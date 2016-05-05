name "chef-dk"
default_version "local_source"

license :project_license

# For the specific super-special version "local_source", build the source from
# the local git checkout. This is what you'd want to occur by default if you
# just ran omnibus build locally.
version("local_source") do
  source path: File.expand_path("../..", project.files_path),
         # Since we are using the local repo, we try to not copy any files
         # that are generated in the process of bundle installing omnibus.
         # If the install steps are well-behaved, this should not matter
         # since we only perform bundle and gem installs from the
         # omnibus cache source directory, but we do this regardless
         # to maintain consistency between what a local build sees and
         # what a github based build will see.
         options: { exclude: [ "omnibus/vendor" ] }
end

# For any version other than "local_source", fetch from github.
if version != "local_source"
  source git: "git://github.com/chef/chef-dk.git"
end

# For nokogiri
dependency "libxml2"
dependency "libxslt"
dependency "libiconv"
dependency "liblzma"
dependency "zlib"

# For berkshelf
dependency "libarchive"

# ruby and bundler and friends
dependency "ruby"
dependency "rubygems"
dependency "bundler"

build do
  # This is where we get the definitions below
  require_relative "../../files/chef-dk/build-chef-dk"
  extend BuildChefDK

  # Prepare to install
  create_bundle_config(retries: 4, jobs: 4, frozen: true)
  use_platform_specific_lockfile

  # Install all the things. Arguments are specified in .bundle/config (see create_bundle_config)
  bundle "install --verbose", env: env
  bundle "check", env: env

  # appbundle and fix up git-sourced gems
  properly_reinstall_git_and_path_sourced_gems
  install_gemfile
  appbundle_gems %w(berkshelf chef chef-dk test-kitchen)

  # For whatever reason, nokogiri software def deletes this (rather small) directory
  block "Remove mini_portile test dir" do
    mini_portile = shellout!("#{bundle_bin} show mini_portile").stdout.chomp
    remove_directory File.join(mini_portile, "test")
  end
end
