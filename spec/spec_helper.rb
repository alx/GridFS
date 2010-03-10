require 'rubygems'
require 'sinatra'
require 'spec'
require 'spec/interop/test'
require 'rack/test'

# set test environment
Sinatra::Base.set :environment, :test
Sinatra::Base.set :run, false
Sinatra::Base.set :raise_errors, true
Sinatra::Base.set :logging, false

require 'application'

Spec::Runner.configure do |config|
  
  config.before(:each) {
    @db = Connection.new('localhost').db('gridfs-test')
    @foo_file = Rack::Test::UploadedFile.new(File.join(Dir.pwd, 'spec', 'foo.png'), "image/png",  true)
    @bar_file = Rack::Test::UploadedFile.new(File.join(Dir.pwd, 'spec', 'bar.png'), "image/png",  true)
  }
  
  config.after(:each) {
    @db.collection('fs.files').remove
    @db.collection('fs.chunks').remove
    @db.collection('profiles').remove
  }
end
