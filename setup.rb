$LOAD_PATH << '.' << './lib'
require 'json'
require 'http'


begin
  # Load Models
  
rescue StandardError => e
  puts e.message
end
