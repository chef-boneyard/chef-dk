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
dependency "liblzma"
dependency "zlib"

# For berkshelf
dependency "libarchive"

# For opscode-pushy-client
if windows?
  dependency "libzmq4x-windows"
else
  dependency "libzmq"
end

# ruby and bundler and friends
dependency "ruby"
dependency "rubygems"
dependency "bundler"
dependency "appbundler"


build do
  env = with_standard_compiler_flags(with_embedded_path)

  excluded_groups = %w{server docgen maintenance pry travis integration ci}
  excluded_groups << "ruby_prof" if aix?
  excluded_groups << "ruby_shadow" if aix?

  # install the whole bundle first
  bundle "install --without #{excluded_groups.join(' ')}", env: env

  gem "build chef-dk.gemspec", env: env

  gem "install chef*.gem --no-ri --no-rdoc --verbose", env: env

  env["NOKOGIRI_USE_SYSTEM_LIBRARIES"] = "true"

  appbundle "berkshelf", lockdir: project_dir, without: %w{guard changelog}, env:env
  appbundle "chef", lockdir: project_dir, without: %w{changelog integration docgen maintenance ci travis}, env:env
  appbundle "test-kitchen", lockdir: project_dir, without: %w{changelog provisioning}, env: env

  %w{chef-dk chef-vault foodcritic ohai opscode-pushy-client cookstyle inspec dco}.each do |gem|
    appbundle gem, lockdir: project_dir, without: %w{changelog}, env: env
  end

  # Clear the now-unnecessary git caches, cached gems, and git-checked-out gems
  block "Delete bundler git cache and git installs" do
    gemdir = shellout!("#{install_dir}/embedded/bin/gem environment gemdir", env: env).stdout.chomp
    remove_directory "#{gemdir}/cache"
    remove_directory "#{gemdir}/bundler"
  end

  # Clean up docs
  delete "#{install_dir}/embedded/docs"
  delete "#{install_dir}/embedded/share/man"
  delete "#{install_dir}/embedded/share/doc"
  delete "#{install_dir}/embedded/share/gtk-doc"
  delete "#{install_dir}/embedded/ssl/man"
  delete "#{install_dir}/embedded/man"
  delete "#{install_dir}/embedded/info"
end
