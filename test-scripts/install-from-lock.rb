$:.unshift File.expand_path("../lib", __FILE__)

require 'pp'
require 'json'
require 'chef-dk'
require 'chef-dk/policyfile_compiler'

HERE = File.expand_path(File.dirname(__FILE__))

lockfile_path = File.join(HERE, "Policyfile.lock.json")

policy_data = JSON.parse(IO.read(lockfile_path))

storage_config = ChefDK::Policyfile::StorageConfig.new.use_policyfile_lock(lockfile_path)
policy_lock = ChefDK::PolicyfileLock.new(storage_config).build_from_lock_data(policy_data)

policy_lock.install_cookbooks
