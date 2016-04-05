name "chef-dk-appbundle"
default_version "local_source"
source path: project.files_path

dependency "chef-dk"

build do
  # This is where we get the definitions below
  require_relative "../../files/chef-dk/build-chef-dk"
  extend BuildChefDK

  appbundle_gem "berkshelf"
  appbundle_gem "chef"
  appbundle_gem "chef-dk"
  appbundle_gem "test-kitchen"
end
