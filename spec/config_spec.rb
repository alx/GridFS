require "#{File.dirname(__FILE__)}/spec_helper"

describe 'config spec' do
  include Rack::Test::Methods

  def app
    Sinatra::Application.new
  end
  
  specify 'should have an admin user by default' do
    admin = @db.collection('profiles').find_one({:admin => true})
    assert Profile, admin.class
  end

end