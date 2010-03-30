#
# API to access GridFS
#
# Protocol from BaconFile
# http://baconfile.com/api/
#

#
# Recent Files
#
# GET http://media.tetalab.org/api/public.format
#
# Format
# json, xml, rss, atom
#
# Try it
# http://media.tetalab.org/api/public.json
#

get "/api/:username/public.:format" do
  content_type params[:format]
  
  media_params = {"site_name" => request.host,
    "username" => params[:username]}
  
  if recent_files = Media.find(options.db, media_params, {:limit => 20})
    
    case params[:format]
    when "xml"
    when "rss"
    when "atom"
    else
      # Send back json
      if callback = request.env["rack.request.query_hash"]["callback"]
        "#{callback}(#{recent_files.to_json})"
      else
        recent_files.to_json
      end
    end
  end
end

#
# Verify Auth
#
# GET https://media.tetalab.org/api/verify.format
#
# Auth
# HTTP basic authentication
#
# Format
# json, xml
#
# Notes
# Use this method to check if the user is properly logged in.
#

get "/api/:username/verify.:format" do
  unless logged_in?
    login_required
  else
    result = {'verify' => :connected}
    
    case params[:format]
    when "xml"
    else
      # Send back json
      if callback = request.env["rack.request.query_hash"]["callback"]
        "#{callback}(#{result.to_json})"
      else
        result.to_json
      end
    end
  end
end

#
# Folder
#
# GET http://media.tetalab.org/api/username/myfolder.format
#
# Format
# json, xml, rss, atom
#
# Try it
# http://media.tetalab.org/api/alx/images.json
#

get "/api/:username/:folders.:format" do
  content_type params[:format]
  
  media_params = {"site_name" => request.host,
    "username" => params[:username]}
  
  folder_array = params[:folders].split("/")
  if folder_array.size == 1
    media_params["folder"] = folder_array.first
  else
    media_params["parent_folder"], media_params["folder"] = folder_array
  end
  
  if recent_files = Media.find(options.db, media_params, {:limit => 20})
    
    case params[:format]
    when "xml"
    when "rss"
    when "atom"
    else
      # Send back json
      if callback = request.env["rack.request.query_hash"]["callback"]
        "#{callback}(#{recent_files.to_json})"
      else
        recent_files.to_json
      end
    end
  end
end

#
# File
#
# GET http://media.tetalab.org/api/username/myfolder/myfile.format
#
# Format
# json, xml
#
# Try it
# http://media.tetalab.org/api/alx/luned.jpg.json
#

get "/api/:username/file/:myfile.:format" do
  content_type params[:format]
  
  media_params = {"site_name" => request.host,
    "username" => params[:username],
    "file" => params[:myfile]}
  
  if recent_files = Media.find(options.db, media_params, {:limit => 20})
    
    case params[:format]
    when "xml"
    when "rss"
    when "atom"
    else
      # Send back json
      if callback = request.env["rack.request.query_hash"]["callback"]
        "#{callback}(#{recent_files.to_json})"
      else
        recent_files.to_json
      end
    end
  end
end

#
# New File
#
# POST https://media.tetalab.org/api/username.format
#
# Auth
# HTTP basic authentication
#
# Format
# json, xml
#
# Params
# folder - folder name
# parent_folder - parent folder name
# file - the file to upload
#
# Notes
# It's a good idea to set the Content-Type header to ensure that Baconfile gets the correct file type.
#

post "/api/:username.:format" do
  if require_administrative_privileges

    # store media
    media = Media.new(options.db, params)
    media.store
    if media.error || !media.saved?
      p "error: #{media.error}"
      error 404, media.error
    else
      metadata = {"username" => params[:username],
        "folder" => params[:folder],
        "parent_folder" => params[:parent_folder]}
      Media.update(options.db, media.options["_id"], metadata)
    end

    # Return success status with file information
    {'status' => 'success', 'media' => media.to_json}.to_json
  end
end

#
# Delete File or Folder
#
# DELETE https://media.tetalab.org/api/username/myfile.format
#
# Auth
# HTTP basic authentication
#
# Format
# json, xml
#

delete "/api/:username/:myfile.:format" do
  if require_administrative_privileges
    if media = Media.find(options.db, {"username" => params[:username]}, {:filename => params[:myfile]})
      Media.remove(options.db, media._id)
    end
  end
end