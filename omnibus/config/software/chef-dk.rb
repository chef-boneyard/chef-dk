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
dependency "libarchive"

#
# NOTE: NO GEM DEPENDENCIES
#
# we do not add dependencies here on omnibus-software definitions that install gems.
#
# all of the gems for chef-dk must be installed in the mega bundle install below.
#
# doing bundle install / rake install in dependent software definitions causes gemsets
# to get solved without some of the chef-dk constraints, which results in multiple different
# versions of gems in the omnibus bundle.
#
# for gems that depend on c-libs, we include the c-libraries directly here.
#

# For berkshelf
dependency "libarchive"

# For opscode-pushy-client
dependency "libzmq"

# ruby and bundler and friends
dependency "ruby"
dependency "rubygems"
dependency "bundler" # technically a gem, but we gotta solve the chicken-egg problem here

# for train
dependency "google-protobuf"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  excluded_groups = %w{server docgen maintenance pry travis integration ci}

  # install the whole bundle first
  bundle "install --without #{excluded_groups.join(' ')}", env: env

  gem "build chef-dk.gemspec", env: env

  gem "install chef*.gem --no-document --verbose", env: env

  env["NOKOGIRI_USE_SYSTEM_LIBRARIES"] = "true"

  appbundle "chef", lockdir: project_dir, gem: "chef", without: %w{integration docgen maintenance ci travis}, env: env
  appbundle "foodcritic", lockdir: project_dir, gem: "foodcritic", without: %w{development}, env: env
  appbundle "test-kitchen", lockdir: project_dir, gem: "test-kitchen", without: %w{changelog debug docs}, env: env
  appbundle "inspec", lockdir: project_dir, gem: "inspec", without: %w{deploy tools maintenance integration}, env: env

  %w{chef-dk chef-apply chef-vault ohai opscode-pushy-client cookstyle dco berkshelf}.each do |gem|
    appbundle gem, lockdir: project_dir, gem: gem, without: %w{changelog}, env: env
  end

  # Clear git-checked-out gems (most of this cleanup has been moved into the chef-cleanup omnibus-software definition,
  # but chef-client still needs git-checked-out gems)
  block "Delete bundler git installs" do
    gemdir = shellout!("#{install_dir}/embedded/bin/gem environment gemdir", env: env).stdout.chomp
    remove_directory "#{gemdir}/bundler"
  end
end
