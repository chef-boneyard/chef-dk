require 'pp'

require 'json'
require 'chef-dk'
require 'chef-dk/policyfile_compiler'
require 'chef-dk/lockfile_uploader'

POLICY_GROUP = "testing"

$hax_mode = true

DEBUG_LOADER = false

KNIFE_CONFIG = "~/.chef/knife.rb"
KNIFE_CONFIG_FULL_PATH = File.expand_path(KNIFE_CONFIG)

Chef::Config.from_file(KNIFE_CONFIG_FULL_PATH)

# Chef Zero:
Chef::Config.chef_server_url = "http://localhost:8889"

Chef::Log.init(STDERR)
Chef::Log.level = :info
Chef::Log.level = :debug if DEBUG_LOADER


HERE = File.expand_path(File.dirname(__FILE__))

lockfile_path = File.join(HERE, "Policyfile.lock.json")

policy_data = JSON.parse(IO.read(lockfile_path))

storage_config = ChefDK::Policyfile::StorageConfig.new.use_policyfile_lock(lockfile_path)
policy_lock = ChefDK::PolicyfileLock.new(storage_config).build_from_lock_data(policy_data)

ChefDK::LockfileUploader.new(policy_lock, POLICY_GROUP).upload
