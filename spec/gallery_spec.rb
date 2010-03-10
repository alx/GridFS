require "#{File.dirname(__FILE__)}/spec_helper"

describe 'gallery spec' do
  include Rack::Test::Methods
  
  def app
    Sinatra::Application.new
  end
  
  specify 'should create a gallery with valid json in return' do
    user_params = {:username => "test", :password => "password", :admin => true}
    @db.collection('profiles').save(user_params)
  
    post '/', { :file => @foo_file, :metadata => {:gallery_id => 1},
                :login => {:username => "test", :password => "password"} }
    post '/', { :file => @bar_file, :metadata => {:gallery_id => 1},
                :login => {:username => "test", :password => "password"} }
                
    get '/gallery/1'
    assert_equal 200, last_response.status
    assert_equal "application/json", last_response.headers["Content-Type"]
    
    gallery = JSON.parse(last_response.body)
    assert_equal 2, gallery.size
    assert_equal "foo.png", gallery.first["filename"]
    assert_equal File.size(@foo_file.path), gallery.first["length"]
    assert_equal "bar.png", gallery.last["filename"]
    assert_equal File.size(@bar_file.path), gallery.last["length"]
    
    get '/gallery/1/foo.png'
    assert_equal 200, last_response.status
    assert_equal "image/png", last_response.headers["Content-Type"]
    assert_equal File.size(@foo_file.path), last_response.headers["Content-Length"].to_i
    
    get '/gallery/1/bar.png'
    assert_equal 200, last_response.status
    assert_equal "image/png", last_response.headers["Content-Type"]
    assert_equal File.size(@bar_file.path), last_response.headers["Content-Length"].to_i
    
    get '/gallery/2'
    assert_equal 404, last_response.status
    
    get '/gallery/2/bar.png'
    assert_equal 404, last_response.status
  end
  
  specify 'should create a gallery with site_id parameter' do
    user_params = {:username => "test", :password => "password", :admin => true}
    @db.collection('profiles').save(user_params)
  
    post '/', { :file => @foo_file, :metadata => {:gallery_id => 1, :site_id => 7},
                :login => {:username => "test", :password => "password"} }
    post '/', { :file => @bar_file, :metadata => {:gallery_id => 1, :site_id => 7},
                :login => {:username => "test", :password => "password"} }
                
    get '/site/7/gallery/1'
    assert_equal 200, last_response.status
    assert_equal "application/json", last_response.headers["Content-Type"]
    
    gallery = JSON.parse(last_response.body)
    assert_equal 2, gallery.size
    assert_equal "foo.png", gallery.first["filename"]
    assert_equal File.size(@foo_file.path), gallery.first["length"]
    assert_equal "bar.png", gallery.last["filename"]
    assert_equal File.size(@bar_file.path), gallery.last["length"]
    
    get '/site/7/gallery/1/foo.png'
    assert_equal 200, last_response.status
    assert_equal "image/png", last_response.headers["Content-Type"]
    assert_equal File.size(@foo_file.path), last_response.headers["Content-Length"].to_i
    
    get '/site/7/gallery/1/bar.png'
    assert_equal 200, last_response.status
    assert_equal "image/png", last_response.headers["Content-Type"]
    assert_equal File.size(@bar_file.path), last_response.headers["Content-Length"].to_i
    
    get '/site/7/gallery/2'
    assert_equal 404, last_response.status
    
    get '/site/7/gallery/2/bar.png'
    assert_equal 404, last_response.status
  end
  
end