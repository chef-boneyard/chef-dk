name "chef-dk-appbundle"
default_version "local_source"
source path: project.files_path

dependency "chef-dk"

build do
  # This is where we get the definitions below
  require_relative "../../files/chef-dk-appbundle/build-chef-dk-appbundle"
  extend BuildChefDKAppbundle

  appbundle_gem "berkshelf"
  appbundle_gem "chef"
  appbundle_gem "chef-dk"
  appbundle_gem "test-kitchen"

  # These need to have their Gemfiles locked down so that their tests will run
  lockdown_gem "fauxhai"
  lockdown_gem "knife-spork"
  lockdown_gem "kitchen-vagrant"
  lockdown_gem "inspec"
end
