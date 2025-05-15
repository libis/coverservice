$LOAD_PATH << '.' << './lib'
require 'sqlite3'
require 'sequel'

require 'app/controllers/main_controller'

Sequel::Model.plugin :json_serializer
$DB = Sequel.sqlite(DataCollector::ConfigFile[:db], loggers: [Logger.new($stdout)])
$DB.run( File.read( File.join(__dir__,'db/clean_audit.sql') ))
