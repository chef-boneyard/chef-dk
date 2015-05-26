1. You will need a knife.rb here that points at your desired chef server
2. Replace USERNAME with your user's username
3. Replace ORG_SHORTNAME with your own org's shortname
4. Place your user's pem key in this .chef directory alongside the knife.rb
5. Place your org's validator key in this .chef directory alongside the knife.rb

Something like this will work as a simple knife.rb

current_dir = File.dirname(__FILE__)
log_level                :info
log_location             STDOUT
node_name                "USERNAME"
client_key               "#{current_dir}/USERNAME.pem"
validation_client_name   "ORG_SHORTNAME-validator"
validation_key           "#{current_dir}/ORG_SHORTNAME-validator.pem"
chef_server_url         "https://api.opscode.com/organizations/ORG_SHORTNAME"
