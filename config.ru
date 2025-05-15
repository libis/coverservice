$LOAD_PATH << '.' << './lib'
require 'sqlite3'
require 'sequel'

require 'logger'
require 'sinatra'
require 'http/accept'
require 'app/controllers/main_controller'

use Rack::RewindableInput::Middleware
# disable :method_override
#
# use Rack::MethodOverride


##Setup database
Sequel::Model.plugin :json_serializer
$DB = Sequel.sqlite(DataCollector::ConfigFile[:db], loggers: [Logger.new($stdout)])
$DB.run( File.read('./config/db/covers.sql') )
$DB.run( File.read('./config/db/initial.sql') )
# $DB.results_as_hash = true

# Load Models
Dir.glob('./app/models/*.rb').sort.each do |file|
  puts "Loading model from #{file}"
  require file
end


map "/#{DataCollector::ConfigFile[:endpoint]}" do
  puts "Loading .......... [ #{DataCollector::ConfigFile[:endpoint]} ]........................"
  run MainController
end