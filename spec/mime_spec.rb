require "#{File.dirname(__FILE__)}/spec_helper"

describe 'mime spec' do
  include Rack::Test::Methods
  
  def app
    Sinatra::Application.new
  end
  
  specify 'should create related thumbnail when uploading images' do
    user_params = {:username => "test", :password => "password", :admin => true}
    @db.collection('profiles').save(user_params)
  
    post '/', { :file => @bar_file,
                :login => {:username => "test", :password => "password"} }
    assert_equal 200, last_response.status
    assert GridStore.exist?(@db, @bar_file.original_filename)
    assert GridStore.exist?(@db, @bar_file.original_filename)
  
    assert_equal 4, GridStore.list(@db).size
  end
  
end