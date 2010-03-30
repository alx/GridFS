require "#{File.dirname(__FILE__)}/spec_helper"

# rake spec SPEC=spec/api_spec.rb

describe 'API spec' do
  include Rack::Test::Methods

  def app
    Sinatra::Application.new
  end
  
  specify 'should authentify user' do
    user_params = {:username => "test", :password => "password", :admin => true}
    @db.collection('profiles').save(user_params)
    
    get '/api/invalid/verify.json'
    assert_equal 302, last_response.status
    
    post '/login', {'email' => "", 'password' => TestHelper.gen_user['user[password]']}
    follow_redirect!

    assert_equal 'http://example.org/', last_request.url
    #assert cookie_jar['user']
    assert last_request.env['rack.session'][:user]
    assert last_response.ok?
    
  end
  
  specify 'should post new file' do
    user_params = {:username => "test", :password => "password", :admin => true}
    @db.collection('profiles').save(user_params)
  end
  
  specify 'should get recent files' do
    user_params = {:username => "test", :password => "password", :admin => true}
    @db.collection('profiles').save(user_params)
    
    post '/', { :file => @bar_file, :metadata => {:site_id => 7, :media_id => 15},
                :login => {:username => "test", :password => "password"} }
    
    get '/su-london/15.jpg'
    assert_equal 200, last_response.status
    assert_equal "image/png", last_response.headers["Content-Type"]
    assert_equal File.size(@bar_file.path), last_response.headers["Content-Length"].to_i
  end

end