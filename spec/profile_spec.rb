require "#{File.dirname(__FILE__)}/spec_helper"

describe 'profile spec' do
  include Rack::Test::Methods

  def app
    Sinatra::Application.new
  end
  
  specify 'should not allow non-admin in profile settings' do
    user_params = {:username => "test", :password => "password"}
    @db.collection('profiles').save(user_params)
    post '/profiles', {:login => user_params}
    assert_equal 401, last_response.status
  end
  
  specify 'should allow admin in profile settings' do
    user_params = {:username => "test", :password => "password", :admin => true}
    @db.collection('profiles').save(user_params)
    post '/profiles', {:login => user_params}
    assert_equal 200, last_response.status
  end

  specify 'should add user in db' do
    admin_params = {:username => "test", :password => "password", :admin => true}
    user_params = {:username => "test2", :password => "password"}
    @db.collection('profiles').save(admin_params)
    post '/profiles', {:login => admin_params}
    profile_count = @db.collection('profiles').size
    post '/profiles', { :login => admin_params,
                        :profile => user_params}
    assert_equal 200, last_response.status
    assert_equal (profile_count + 1), @db.collection('profiles').size
  end
  
  specify 'should add user in db with site_id metadata' do
    @db.collection('profiles').save({:username => "test", :password => "password", :admin => true})
    profile_count = @db.collection('profiles').size
    post '/profiles', { :login => {:username => "test", :password => "password"},
                        :profile => {:username => "test2", :password => "password", :site_id => 6}}
    assert_equal 200, last_response.status
    
    profile = @db.collection('profiles').find_one({:username => "test2"})
    profile["site_id"] = 6
  end
  
  specify 'should allow user to upload to site_id' do
    @db.collection('profiles').save({:username => "test", :password => "password", :site_id => 6})
    metadata = {:site_id => 6, :app_name => "widget"}
    post '/', { :file => @bar_file, :metadata  => metadata,
                :login => {:username => "test", :password => "password"} }
    assert_equal 200, last_response.status
  end
  
  specify 'should not allow user to upload to site_id' do
    @db.collection('profiles').save({:username => "test", :password => "password", :site_id => 6})
    metadata = {:site_id => 3, :app_name => "widget"}
    post '/', { :file => @bar_file, :metadata  => metadata,
                :login => {:username => "test", :password => "password"} }
    assert_equal 401, last_response.status
  end

end
