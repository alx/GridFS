require "#{File.dirname(__FILE__)}/spec_helper"

describe 'manage spec' do
  include Rack::Test::Methods

  def app
    Sinatra::Application.new
  end
  
  specify 'should delete an object' do
    user_params = {:username => "test", :password => "password", :admin => true}
    @db.collection('profiles').save(user_params)
  
    post '/', { :file => @foo_file, :metadata => {:no_thumb => true, :site_id => 1, :app_name => 'media', :folder_id => 50},
                :login => {:username => "test", :password => "password"} }
    post '/', { :file => @bar_file, :metadata => {:no_thumb => true, :site_id => 1, :app_name => 'media', :folder_id => 50},
                :login => {:username => "test", :password => "password"} }
  
    get '/site/1/media/folder/50'
    assert_equal 200, last_response.status
    assert_equal "application/json", last_response.content_type
    
    medias = JSON.parse(last_response.body)
    assert_equal 2, medias.size
    assert_not_nil medias.first["id"]
    
    assert_equal 2, @db.collection('fs.files').count
    
    post "/delete/#{medias.first["id"]}", {:login => {:username => "test", :password => "password"}}
    assert_equal 200, last_response.status
    
    get '/site/1/media/folder/50'
    assert_equal 200, last_response.status
    resized_medias = JSON.parse(last_response.body)
    assert_equal 1, resized_medias.size
    assert_not_equal medias.first["id"], resized_medias.first["id"]
    assert_equal medias.last["id"], resized_medias.first["id"]
    
    assert_equal 1, @db.collection('fs.files').count
    
    post "/delete/#{medias.last["id"]}", {:login => {:username => "test", :password => "password"}}
    assert_equal 200, last_response.status
    
    get '/site/1/media/folder/50'
    assert_equal 404, last_response.status
    
    assert_equal 0, @db.collection('fs.files').count
  end
  
  specify 'should delete thumbnails' do
    user_params = {:username => "test", :password => "password", :admin => true}
    @db.collection('profiles').save(user_params)
  
    post '/', { :file => @foo_file, :metadata => {:site_id => 1, :app_name => 'media', :folder_id => 50},
                :login => {:username => "test", :password => "password"} }
    
    assert_equal 4, @db.collection('fs.files').count
    
    get '/site/1/media/folder/50'
    media_id = JSON.parse(last_response.body).first["id"]
    assert_not_nil media_id
    
    post "/delete/#{media_id}", {:login => {:username => "test", :password => "password"}}
    assert_equal 200, last_response.status
    
    assert_equal 0, @db.collection('fs.files').count
  end
  
  specify 'should update an object' do
    user_params = {:username => "test", :password => "password", :admin => true}
    @db.collection('profiles').save(user_params)
  
    post '/', { :file => @foo_file, :metadata => {:no_thumb => true, :site_id => 1, :app_name => 'media', :folder_id => 50},
                :login => {:username => "test", :password => "password"} }
    get '/site/1/media/folder/50'
    assert_equal 200, last_response.status
    assert_equal "application/json", last_response.content_type

    medias = JSON.parse(last_response.body)
    assert_equal 1, medias.size
    assert_equal "media", medias.first["metadata"]["app_name"]
    assert_nil medias.first["metadata"]["name"]
    
    post "/edit/#{medias.first["id"]}", 
        {:login => {:username => "test", :password => "password"}, 
        :metadata => {:name => "test"}}
    assert_equal 200, last_response.status
    
    get '/site/1/media/folder/50'
    assert_equal 200, last_response.status
    
    medias = JSON.parse(last_response.body)
    assert_equal 1, medias.size
    assert_equal "media", medias.first["metadata"]["app_name"]
    assert_equal "test", medias.first["metadata"]["name"]
    
    post "/edit/#{medias.first["id"]}", 
        {:login => {:username => "test", :password => "password"}, 
        :metadata => {:name => "test2"}}
    assert_equal 200, last_response.status
    
    get '/site/1/media/folder/50'
    assert_equal 200, last_response.status
    
    medias = JSON.parse(last_response.body)
    assert_equal 1, medias.size
    assert_equal "media", medias.first["metadata"]["app_name"]
    assert_equal "test2", medias.first["metadata"]["name"]
  end
end
