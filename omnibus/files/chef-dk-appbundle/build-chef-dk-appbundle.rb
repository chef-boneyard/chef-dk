require_relative "../chef-dk-gem/build-chef-dk-gem"

module BuildChefDKAppbundle
  include BuildChefDKGem

  #
  # Get the (possibly platform-specific) path to the Gemfile.
  #
  def chefdk_project_dir
    File.join(project_dir, "..", "chef-dk")
  end

  def lockdown_gem(gem_name)
    chefdk_project_dir = self.chefdk_project_dir
    shared_gemfile = self.shared_gemfile

    # Update the Gemfile to restrict to built versions so that bundle installs
    # will do the right thing
    block "Lock down the #{gem_name} gem" do

      installed_path = shellout!("#{bundle_bin} show #{gem_name}", env: env, cwd: chefdk_project_dir).stdout.chomp
      installed_gemfile = File.join(installed_path, "Gemfile")

      #
      # Include the main distribution Gemfile in the gem's Gemfile
      #
      # NOTE: if this fails and the build retries, you will see this multiple
      # times in the file.
      #
      distribution_gemfile = Pathname(shared_gemfile).relative_path_from(Pathname(installed_gemfile)).to_s
      gemfile_text = <<-EOM.gsub(/^\s+/, "")
        # Lock gems that are part of the distribution
        distribution_gemfile = File.expand_path(#{distribution_gemfile.inspect}, __FILE__)
        instance_eval(IO.read(distribution_gemfile), distribution_gemfile)
      EOM

      # not all gems ship a Gemfile. it's all right. we love them anyway.
      gemfile_text << IO.read(installed_gemfile) if File.exists?(installed_gemfile)
      create_file(installed_gemfile) { gemfile_text }

      # Remove the gemfile.lock
      remove_file("#{installed_gemfile}.lock") if File.exist?("#{installed_gemfile}.lock")

      installed_gemspec = File.join(installed_path, "#{gem_name}.gemspec")

      # appbundler needs a Gemfile.lock, which furthermore has to contain the gem itself. and that only
      # happens when the Gemfile includes a gemspec.
      if !File.exists?(installed_gemspec)
        full_gem_name = File.basename(installed_path)
        spec_path = File.expand_path("../../specifications", installed_path)
        copy_file(windows_safe_path(File.join(spec_path, "#{full_gem_name}.gemspec")), installed_gemspec)
        shellout!("echo gemspec >> #{installed_gemfile}")
      end

      # If it's frozen, make it not be.
      shellout!("#{bundle_bin} config --delete frozen", cwd: installed_path)

      # This could be changed to `bundle install` if we wanted to actually
      # install extra deps out of their gemfile ...
      shellout!("#{bundle_bin} lock", env: env, cwd: installed_path)
      # bundle lock doesn't always tell us when it fails, so we have to check :/
      unless File.exist?("#{installed_gemfile}.lock")
        raise "bundle lock failed: no #{installed_gemfile}.lock created!"
      end

      # Ensure all the gems we need are actually installed (if the bundle adds
      # something, we need to know about it so we can include it in the main
      # solve).
      # Save bundle config and modify to use --without development before checking
      bundle_config = File.expand_path("../.bundle/config", installed_gemfile)
      orig_config = IO.read(bundle_config) if File.exist?(bundle_config)
      # "test", "changelog" and "guard" come from berkshelf, "maintenance" comes from chef
      # "tools" and "integration" come from inspec
      shellout!("#{bundle_bin} config --local without #{without_groups.join(":")}", env: env, cwd: installed_path)
      shellout!("#{bundle_bin} config --local frozen 1")

      shellout!("#{bundle_bin} check", env: env, cwd: installed_path)

      # Restore bundle config
      if orig_config
        create_file(bundle_config) { orig_config }
      else
        remove_file bundle_config
      end
    end
  end

  # appbundle the gem, making /opt/chefdk/bin/<binary> do the superfast pinning
  # thing.
  #
  # To protect the app from loading the wrong versions of things, it uses
  # appbundler against the resulting file.
  #
  # Relocks the Gemfiles inside the specified gems (e.g. berkshelf, test-kitchen,
  # chef) to use the distribution's chosen gems.
  def appbundle_gem(gem_name)
    # First lock the gemfile down.
    lockdown_gem(gem_name)

    # Ensure the main bin dir exists
    bin_dir = File.join(install_dir, "bin")
    mkdir(bin_dir)

    chefdk_project_dir = self.chefdk_project_dir

    block "Lock down the #{gem_name} gem" do
      installed_path = shellout!("#{bundle_bin} show #{gem_name}", env: env, cwd: chefdk_project_dir).stdout.chomp

      # appbundle the gem
      appbundler_args = [ installed_path, bin_dir, gem_name ]
      appbundler_args = appbundler_args.map { |a| ::Shellwords.escape(a) }
      shellout!("#{appbundler_bin} #{appbundler_args.join(" ")}", env: env, cwd: installed_path)
    end
  end
end
