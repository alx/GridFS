require "#{File.dirname(__FILE__)}/spec_helper"

  #
  # Specify your tests here and launch with: rake spec SPEC=spec/latest_spec.rb
  #

describe 'latest spec' do
  include Rack::Test::Methods

  def app
    Sinatra::Application.new
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

end