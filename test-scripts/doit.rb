$:.unshift File.expand_path("../lib", __FILE__)

require 'pp'
require 'chef-dk'
require 'chef-dk/policyfile_compiler'

policyfile_path = File.expand_path("../Policyfile.rb", __FILE__)
policyfile_content = IO.read(policyfile_path)

policy = ChefDK::PolicyfileCompiler.evaluate(policyfile_content, policyfile_path)
policy.error!

pp policy.graph_solution.sort


