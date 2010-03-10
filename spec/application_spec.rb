require "#{File.dirname(__FILE__)}/spec_helper"

describe 'main application' do
  include Rack::Test::Methods

  def app
    Sinatra::Application.new
  end
  
  specify 'should return 404 if file not found' do
    get "/not_found.png"
    assert_equal 404, last_response.status
  end

  specify 'should show the default index page' do
    get '/'
    last_response.status.should == 200
    last_response.body.should =~ /Service to manage web file storage/
  end
  
end
