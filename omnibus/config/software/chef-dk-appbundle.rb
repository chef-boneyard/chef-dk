name "chef-dk-appbundle"

license :project_license

default_version "local_source"
source path: project.files_path

dependency "chef-dk"

build do
  # This is where we get the definitions below
  require_relative "../../files/chef-dk-appbundle/build-chef-dk-appbundle"
  extend BuildChefDKAppbundle

  appbundle_gem "chef-dk"
  appbundle_gem "berkshelf"
  appbundle_gem "chef-vault"
  appbundle_gem "chef"
  appbundle_gem "foodcritic"
  appbundle_gem "ohai"
  appbundle_gem "test-kitchen"
  appbundle_gem "opscode-pushy-client"
  appbundle_gem "cookstyle"
  appbundle_gem "rubocop"
  appbundle_gem "inspec"
  appbundle_gem "dco"

  # These are not appbundled, but need to have their Gemfiles locked down so that their tests will run

  lockdown_gem "fauxhai"
  lockdown_gem "inspec"
  lockdown_gem "kitchen-vagrant"
  lockdown_gem "knife-spork"
end
