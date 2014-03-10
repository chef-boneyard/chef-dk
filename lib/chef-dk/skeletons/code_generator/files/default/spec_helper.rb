require 'chefspec'

current_dir = File.dirname(__FILE__)

RSpec.configure do |config|
  # Point to the cookbooks directory
  config.cookbook_path = File.join(current_dir, '../cookbooks')
end
