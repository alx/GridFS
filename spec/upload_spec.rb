require "#{File.dirname(__FILE__)}/spec_helper"

describe 'upload spec' do
  include Rack::Test::Methods

  def app
    Sinatra::Application.new
  end
  
  specify 'should refuse unauthentiticated upload' do
    post '/', { :file => @bar_file}
    assert_equal 401, last_response.status
  end
  
  specify 'should accept authentiticated upload' do
    
    user_params = {:username => "test", :password => "password", :admin => true}
    @db.collection('profiles').save(user_params)
    
    post '/', { :file => @bar_file,
                :login => {:username => "test", :password => "password"} }
    assert_equal 200, last_response.status
    assert GridStore.exist?(@db, @bar_file.original_filename)
    
    # There're 4 new media, generated with thumbnails
    assert_equal 4, GridStore.list(@db).size
  end
  
  specify 'should not create thumbnails if specified in metadata' do
    
    user_params = {:username => "test", :password => "password", :admin => true}
    @db.collection('profiles').save(user_params)
    
    post '/', { :file => @bar_file, :metadata => {:no_thumb => true},
                :login => {:username => "test", :password => "password"} }
    assert_equal 200, last_response.status
    assert GridStore.exist?(@db, @bar_file.original_filename)
    
    assert_equal 1, GridStore.list(@db).size
  end
  
  specify 'should use metadata to be fetched by url' do
    user_params = {:username => "test", :password => "password", :admin => true}
    @db.collection('profiles').save(user_params)
    
    metadata = {:site_id => 3, :app_name => "widget"}
    post '/', { :file => @bar_file, :metadata  => metadata,
                :login => {:username => "test", :password => "password"} }
    assert_equal 200, last_response.status
    get "/#{metadata[:site_id]}/#{metadata[:app_name]}/bar.png"
    assert_equal 200, last_response.status
    assert_equal "image/png", last_response.content_type
  end
  
  specify 'should find file without app_name' do
    
    user_params = {:username => "test", :password => "password", :admin => true}
    @db.collection('profiles').save(user_params)
    
    metadata = {:site_id => 3}
    post '/', { :file => @bar_file, :metadata  => metadata,
                :login => {:username => "test", :password => "password"} }
    assert_equal 200, last_response.status
    get "/#{metadata[:site_id]}/bar.png"
    assert_equal 200, last_response.status
    assert_equal "image/png", last_response.content_type
  end
  
  specify 'should return valid file after upload' do
    user_params = {:username => "test", :password => "password", :admin => true}
    @db.collection('profiles').save(user_params)
    
    post '/', { :file => @bar_file, :metadata => {:no_thumb => true, :site_id => 1},
                :login => {:username => "test", :password => "password"} }
    
    get '/1/bar.png'
    assert_equal 200, last_response.status
    assert_equal "image/png", last_response.headers["Content-Type"]
    assert_equal File.size(@bar_file.path), last_response.headers["Content-Length"].to_i
  end
  
  specify 'should download a file with a correct size' do
    user_params = {:username => "test", :password => "password", :admin => true}
    @db.collection('profiles').save(user_params)
    
    post '/', { :file => @bar_file, :metadata => {:no_thumb => true, :site_id => 1},
                :login => {:username => "test", :password => "password"} }
    
    get '/download/1/bar.png'
    assert_equal 200, last_response.status
    assert_equal "image/png", last_response.headers["Content-Type"]
    assert_equal File.size(@bar_file.path), last_response.headers["Content-Length"].to_i
  end
  
  specify 'should retrieve file using metadata' do
    user_params = {:username => "test", :password => "password", :admin => true}
    @db.collection('profiles').save(user_params)
    
    post '/', { :file => @bar_file, :metadata => {:site_id => 7, :media_id => 15},
                :login => {:username => "test", :password => "password"} }
    
    get '/su-london/15.jpg'
    assert_equal 200, last_response.status
    assert_equal "image/png", last_response.headers["Content-Type"]
    assert_equal File.size(@bar_file.path), last_response.headers["Content-Length"].to_i
  end
  
  specify 'should not overwrite same filename with different metadata' do
    user_params = {:username => "test", :password => "password", :admin => true}
    @db.collection('profiles').save(user_params)
    
    post '/', { :file => @bar_file, :metadata => {:no_thumb => true, :media_id => 1, :site_id => 7},
                :login => {:username => "test", :password => "password"} }
    assert_equal 200, last_response.status
    
    assert GridStore.exist?(@db, @bar_file.original_filename)
    assert_equal 1, GridStore.list(@db).size
    
    get '/su-london/1.jpg'
    assert_equal 200, last_response.status
    assert_equal File.size(@bar_file.path), last_response.headers["Content-Length"].to_i
    
    # Next file, with same filename, should be a new record in GridStore
    post '/', { :file => @bar_file, :metadata => {:no_thumb => true, :media_id => 2, :site_id => 7},
                :login => {:username => "test", :password => "password"} }
    assert_equal 200, last_response.status
    
    # This file should contains the suffix inside filename
    assert GridStore.exist?(@db, @bar_file.original_filename.gsub(".", "_0."))
    assert_equal 2, GridStore.list(@db).size
    
    get '/su-london/2.jpg'
    assert_equal 200, last_response.status
    assert_equal File.size(@bar_file.path), last_response.headers["Content-Length"].to_i
    
    # Next file, with same filename and same metadata, should not create a new record
    post '/', { :file => @bar_file, :metadata => {:no_thumb => true, :media_id => 2, :site_id => 7},
                :login => {:username => "test", :password => "password"} }
    assert_equal 200, last_response.status
    
    assert GridStore.exist?(@db, @bar_file.original_filename)
    assert_equal 2, GridStore.list(@db).size
    
    get '/su-london/2.jpg'
    assert_equal 200, last_response.status
    assert_equal File.size(@bar_file.path), last_response.headers["Content-Length"].to_i
    
    # Next file, with same filename and same metadata, should be a new record in GridStore
    post '/', { :file => @bar_file, :metadata => {:no_thumb => true, :media_id => 3, :site_id => 7},
                :login => {:username => "test", :password => "password"} }
    assert_equal 200, last_response.status
    
    assert GridStore.exist?(@db, @bar_file.original_filename.gsub(".", "_1."))
    assert_equal 3, GridStore.list(@db).size
    
    get '/su-london/3.jpg'
    assert_equal 200, last_response.status
    assert_equal File.size(@bar_file.path), last_response.headers["Content-Length"].to_i
  end
  
end