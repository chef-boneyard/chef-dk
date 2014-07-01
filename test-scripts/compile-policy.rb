$:.unshift File.expand_path("../lib", __FILE__)

require 'pp'
require 'json'
require 'chef-dk'
require 'chef-dk/policyfile_compiler'

HERE = File.expand_path(File.dirname(__FILE__))

policyfile_path = File.join(HERE, "Policyfile.rb")
policyfile_content = IO.read(policyfile_path)

policy = ChefDK::PolicyfileCompiler.evaluate(policyfile_content, policyfile_path)
policy.error!

puts "Solving Graph"
pp policy.graph_solution.sort

puts "Caching Cookbooks"
policy.install

lock_data = policy.lock.to_lock

puts "Lock Data"
pp lock_data

puts "Writing Lock"

lockfile_path = File.join(HERE, "Policyfile.lock.json")

File.open(lockfile_path, "w+") do |f|
  f.print(JSON.pretty_generate(lock_data))
end


