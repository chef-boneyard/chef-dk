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

# Install all the native gems separately

# Worst offenders first to take best advantage of cache:
dependency "chef-dk-gem-dep-selector-libgecode"
dependency "chef-dk-gem-gherkin"
dependency "chef-dk-gem-byebug"
dependency "chef-dk-gem-nokogiri"

# Now everyone else, in alphabetical order because we don't care THAT much
Dir.entries(File.dirname(__FILE__)).sort.each do |gem_software|
  if gem_software =~ /^(chef-dk-gem-.+)\.rb$/
    dependency $1
  end
end

build do
  # This is where we get the definitions below
  require_relative "../../files/chef-dk/build-chef-dk"
  extend BuildChefDK

  chefdk_build_env = env.dup
  chefdk_build_env["BUNDLE_GEMFILE"] = chefdk_gemfile

  # Prepare to install: build config, retries, job, frozen=true
  # TODO Windows install seems to sometimes install already-installed gems such
  # as gherkin (and fail as a result) if you use jobs: 4.
  create_bundle_config(chefdk_gemfile, retries: 4, jobs: 1, frozen: true)

  # Install all the things. Arguments are specified in .bundle/config (see create_bundle_config)
  block { log.info(log_key) { "" } }
  bundle "install --verbose", env: chefdk_build_env

  # For whatever reason, nokogiri software def deletes this (rather small) directory
  block { log.info(log_key) { "" } }
  block "Remove mini_portile test dir" do
    mini_portile = shellout!("#{bundle_bin} show mini_portile").stdout.chomp
    remove_directory File.join(mini_portile, "test")
  end

  # Check that it worked
  block { log.info(log_key) { "" } }
  bundle "check", env: chefdk_build_env

  # fix up git-sourced gems
  properly_reinstall_git_and_path_sourced_gems
  install_shared_gemfile

  # Check that the final gemfile worked
  block { log.info(log_key) { "" } }
  bundle "check", env: env, cwd: File.dirname(shared_gemfile)
end
