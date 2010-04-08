require 'rubygems'
require 'sinatra'
require 'environment'

Dir['lib/router/*.rb'].each { |routes| require routes.gsub(/\.rb$/, '') }

# =======
#
# Configuration
#
# =======

configure do
  set :views, "#{File.dirname(__FILE__)}/views"
end

configure :production, :development do
  db_connection = Connection.new('localhost', Connection::DEFAULT_PORT).db('gridfs')
  set :db, db_connection
  
  # Verify that admin user exists
  profiles = db_connection.collection('profiles')
  if profiles.nil? || profiles.find_one({:admin => true}).nil?
    init_config = YAML.load_file(File.join(Dir.pwd, 'init_config.yaml'))
    profiles.save(init_config["admin-login"])
  end
end

configure :test do
  db_connection = Connection.new('localhost', Connection::DEFAULT_PORT).db('gridfs-test')
  set :db, db_connection
  
  # Verify that admin user exists
  profiles = db_connection.collection('profiles')
  if profiles.nil? || profiles.find_one({:admin => true}).nil?
    init_config = YAML.load_file(File.join(Dir.pwd, 'init_config.yaml'))
    profiles.save(init_config["admin-login"])
  end
end

error do
  e = request.env['sinatra.error']
  Kernel.puts e.backtrace.join("\n")
  'Application error'
end

helpers do
  
  def fetch_media(params, format = nil)
    unless grid_file = Media.new(options.db, params).grid_file
      content_type :json
      error 404
    else
      if grid_file.kind_of?(Array) || format == 'json'
        content_type :json
        
        # If Media class forced into json format
        unless grid_file.kind_of?(Array)
          grid_file = [grid_file]
        end
        
        # Allow limitation of result size
        grid_file = grid_file[0...params[:limit].to_i] if params[:limit]
        # Send back json
        if callback = request.env["rack.request.query_hash"]["callback"]
          "#{callback}(#{grid_file.to_json})"
        else
          grid_file.to_json
        end
      else
        # Send back complete file
        content_type MIME::Types.type_for(grid_file[:filename]).to_s
        GridStore.read(options.db, grid_file[:filename])
      end
    end
  end
  
end

# =======
#
# Homepage
#
# =======

get '/' do
  unless params.empty?
    fetch_media(params)
  else
    erb :root
  end
end


# =======
#
# Manage objects
#
# =======

get '/delete/:objid' do
  content_type :json
  # Validate user login
  profile = Profile.new(options.db, params[:login])
  if profile.error ||
    !profile.is_admin?
    error 401, profile.error
  else
    Media.remove(options.db, params[:objid])
    
    if callback = request.env["rack.request.query_hash"]["callback"]
      "#{callback}(#{{'status' => 'success'}.to_json})"
    else
      {'status' => 'success'}.to_json
    end
  end
end

get '/edit/:objid' do
  content_type :json
  # Validate user login
  profile = Profile.new(options.db, params[:login])
  if profile.error ||
    !profile.is_admin?
    error 401, profile.error
  else
    Media.update(options.db, params[:objid], params[:metadata])
    
    if callback = request.env["rack.request.query_hash"]["callback"]
      "#{callback}(#{{'status' => 'success'}.to_json})"
    else
      {'status' => 'success'}.to_json
    end
  end
end

# =======
#
# Get file
#
# =======

# -------
# General
# -------

get '/gallery/:gallery_id' do
  fetch_media({"metadata" => {"gallery_id" => params[:gallery_id]}})
end

get '/gallery/:gallery_id/:filename' do
  media_params = {:filename => params[:filename], 
                  "metadata" => {"gallery_id" => params[:gallery_id]}}
  fetch_media(media_params)
end

get '/site/:site_id/gallery/:gallery_id' do
  fetch_media({"metadata" => {"site_id" => params[:site_id], "gallery_id" => params[:gallery_id]}})
end

get '/site/:site_id/gallery/:gallery_id/:filename' do
  media_params = {:filename => params[:filename], 
                  "metadata" => {"site_id" => params[:site_id], "gallery_id" => params[:gallery_id]}}
  fetch_media(media_params)
end

get '/site/:site_id/media/folder/:folder_id' do
  fetch_media({"metadata" => {"site_id" => params[:site_id],
                              "app_name" => 'media',
                              "folder_id" => params[:folder_id]}}, 'json')
end

get '/site/:site_id/media/:filename' do
  fetch_media({:filename => params[:filename],
               "metadata" => {"site_id" => params[:site_id], 
                              "app_name" => 'media'}})
end

get '/download/:site_id/:filename' do
  fetch_media(params)
end

# =======
#
# Upload
#
# =======

post '/' do
  content_type :json
  
  # Validate user login
  profile = Profile.new(options.db, params[:login])
  if profile.error
    error 401, profile.error
  end
  
  if params[:metadata] && params[:metadata][:site_id]
    site_id = params[:metadata][:site_id]
  end
  
  if params[:metadata] && 
    params[:metadata][:gallery_name] && 
    params[:metadata][:gallery_url].nil?
    params[:metadata][:gallery_url] = Media.to_permalink(params[:metadata][:gallery_name])
  end
  
  if params[:metadata] && 
    params[:metadata][:portfolio] && 
    params[:metadata][:portfolio_url].nil?
    params[:metadata][:portfolio_url] = Media.to_permalink(params[:metadata][:portfolio])
  end
  
  if profile.is_admin? ||
    (site_id && profile.authorized?(site_id))
    
    # store media
    media = Media.new(options.db, params)
    media.store
    if media.error || !media.saved?
      p "error: #{media.error}"
      error 404, media.error
    end

    # Return success status with file information
    {'status' => 'success', 'media' => media.to_json}.to_json
    
  else
    error 401, "User not authorized on site[#{site_id}]"
  end
end

# =======
#
# Profile setting
#
# =======

post '/profiles' do
  content_type :json
  
  # Validate user login and has admin rights
  profile = Profile.new(options.db, params[:login])
  if profile.error || !profile.is_admin?
    error 401, profile.error
  end
  
  if params[:profile]
    new_profile = Profile.create(options.db, params[:profile])
    # Return success status with file information
    {'status' => 'success', 'profile' => new_profile}.to_json
  else
    {'status' => 'success'}.to_json
  end
end