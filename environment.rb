require 'rubygems'
require 'haml'
require 'ostruct'
require 'htmlentities'
require 'unicode'

require 'sinatra' unless defined?(Sinatra)

require 'json'
require 'mongo'
require 'mongo/gridfs'

require 'mime/types'
require 'mojo_magick'

include Mongo
include GridFS

configure do
  SiteConfig = OpenStruct.new(
                 :title => 'GridFs',
                 :author => '<a href="http://legodata.com">Legodata</a>',
                 :url_base => 'http://gridfs.legodata.com/'
               )

  # load models
  $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib")
  Dir.glob("#{File.dirname(__FILE__)}/lib/*.rb") { |lib| require File.basename(lib, '.*') }
  
  # log = File.new("sinatra.log", "a")
  # STDOUT.reopen(log)
  # STDERR.reopen(log)
end
