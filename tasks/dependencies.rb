#
# Copyright:: Copyright (c) 2016 Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Once you decide that the list of outdated gems is OK, you can just
# add gems to the output of bundle outdated here and we'll parse it to get the
# list of outdated gems.
#
# We're starting with debt here, but don't want it to get worse.

require_relative "bundle_util"
require_relative "../version_policy"

namespace :dependencies do
  # Update all dependencies to the latest constraint-matching version
  task :update, [:conservative] => %w{
                    dependencies:update_chef_current
                    dependencies:update_omnibus_overrides
                    dependencies:update_gemfile_lock
                    dependencies:update_platform_gemfile_locks
                    dependencies:update_omnibus_gemfile_lock
                    dependencies:update_acceptance_gemfile_lock
                    dependencies:update_omnibus_berksfile_lock
                  }

  task :update_gemfile_lock, [:conservative] do |t, conservative: false|
    extend BundleUtil
    puts ""
    puts "-------------------------------------------------------------------"
    puts "Updating Gemfile.lock#{conservative ? " (conservatively)" : ""} ..."
    puts "-------------------------------------------------------------------"
    bundle "install", delete_gemfile_lock: !conservative
  end

  task :update_platform_gemfile_locks, [:conservative] do |t, conservative: false|
    extend BundleUtil
    platforms.each do |platform|
      puts ""
      puts "-------------------------------------------------------------------"
      puts "Updating Gemfile.#{platform}.lock#{conservative ? " (conservatively)" : ""} ..."
      puts "-------------------------------------------------------------------"
      bundle "lock", gemfile: "Gemfile.#{platform}", platform: platform, delete_gemfile_lock: !conservative
    end
  end

  task :update_omnibus_gemfile_lock, [:conservative] do |t, conservative: false|
    extend BundleUtil
    puts ""
    puts "-------------------------------------------------------------------"
    puts "Updating omnibus/Gemfile.lock#{conservative ? " (conservatively)" : ""} ..."
    puts "-------------------------------------------------------------------"
    bundle "install", cwd: "omnibus", delete_gemfile_lock: !conservative
  end

  task :update_omnibus_berksfile_lock, [:conservative] do |t, conservative: false|
    extend BundleUtil
    puts ""
    puts "-------------------------------------------------------------------"
    puts "Updating omnibus/Berksfile.lock#{conservative ? " (conservatively)" : ""} ..."
    puts "-------------------------------------------------------------------"
    if !conservative && File.exist?("#{project_root}/omnibus/Berksfile.lock")
      File.delete("#{project_root}/omnibus/Berksfile.lock")
    end
    bundle "exec berks install", cwd: "omnibus"
  end

  task :update_acceptance_gemfile_lock, [:conservative] do |t, conservative: false|
    extend BundleUtil
    puts ""
    puts "-------------------------------------------------------------------"
    puts "Updating acceptance/Gemfile.lock#{conservative ? " (conservatively)" : ""} ..."
    puts "-------------------------------------------------------------------"
    bundle "install", cwd: "acceptance", delete_gemfile_lock: !conservative
  end

  task :update_chef_current, [:conservative] do |t, conservative: false|
    extend BundleUtil
    unless conservative
      puts ""
      puts "-------------------------------------------------------------------"
      puts "Updating Gemfile ..."
      puts "-------------------------------------------------------------------"

      require "mixlib/install"
      # TODO in some edge cases, stable will actually be the latest chef because
      # promotion *moves* the package out of current into stable rather than
      # copying
      puts "Getting latest chef 'current' version from omnitruck ..."
      options = {
        channel: :current,
        product_name: 'chef',
        product_version: :latest
      }
      version = Mixlib::Install.new(options).artifact_info.first.version

      # Modify the gemfile to pin to current chef
      gemfile_path = File.join(project_root, "Gemfile")
      gemfile = IO.read(gemfile_path)
      found = gemfile.sub!(/^(gem "chef", github: "chef\/chef", branch: ")([^"]*)(")$/m) do
        if $2 != "v#{version}"
          puts "Setting chef version in Gemfile to v#{version} (was #{$2})"
        else
          puts "chef version in Gemfile already at latest current (#{$2})"
        end
        "#{$1}v#{version}#{$3}"
      end
      unless found
        raise "Gemfile does not have a line of the form 'gem \"chef\", github: \"chef/chef\", branch: \"v<version>\"', so we didn't update it to latest current (v#{version}). Remove dependencies:update_current_chef from the `dependencies:update` rake task to prevent it from being run if this is intentional."
      end

      if gemfile != IO.read(gemfile_path)
        puts "Writing modified #{gemfile_path} ..."
        IO.write(gemfile_path, gemfile)
      end
    end
  end

  task :update_omnibus_overrides, [:conservative] do |t, conservative: false|
    unless conservative
      puts ""
      puts "-------------------------------------------------------------------"
      puts "Updating omnibus_overrides.rb ..."
      puts "-------------------------------------------------------------------"

      # Generate the new overrides file
      overrides = "# Generated by \"rake dependencies\". Do not edit.\n"

      # Replace the bundler and rubygems versions
      OMNIBUS_RUBYGEMS_AT_LATEST_VERSION.each do |override_name, gem_name|
        # Get the latest bundler version
        puts "Running gem list -re #{gem_name} ..."
        gem_list = `gem list -re #{gem_name}`
        unless gem_list =~ /^#{gem_name}\s*\(([^)]*)\)$/
          raise "gem list -re #{gem_name} failed with output:\n#{gem_list}"
        end

        # Emit it
        puts "Latest version of #{gem_name} is #{$1}"
        overrides << "override #{override_name.inspect}, version: #{$1.inspect}\n"
      end

      # Add explicit overrides
      OMNIBUS_OVERRIDES.each do |override_name, version|
        overrides << "override #{override_name.inspect}, version: #{version.inspect}\n"
      end

      # Write the file out (if changed)
      overrides_path = File.expand_path("../../omnibus_overrides.rb", __FILE__)
      if overrides != IO.read(overrides_path)
        puts "Overrides changed!"
        puts `git diff #{overrides_path}`
        puts "Writing modified #{overrides_path} ..."
        IO.write(overrides_path, overrides)
      end
    end
  end

  # Find out if we're using the latest gems we can (so we don't regress versions)
  task :check do
    puts ""
    puts "-------------------------------------------------------------------"
    puts "Checking for outdated gems ..."
    puts "-------------------------------------------------------------------"
    # TODO check for outdated windows gems too
    bundle_outdated = bundle("outdated", extract_output: true)
    puts bundle_outdated
    outdated_gems = parse_bundle_outdated(bundle_outdated).map { |line, gem_name| gem_name }
    # Weed out the acceptable ones
    outdated_gems = outdated_gems.reject { |gem_name| ACCEPTABLE_OUTDATED_GEMS.include?(gem_name) }
    if outdated_gems.empty?
      puts ""
      puts "SUCCESS!"
    else
      raise "ERROR: outdated gems: #{outdated_gems.join(", ")}. Either fix them or add them to ACCEPTABLE_OUTDATED_GEMS in #{__FILE__}."
    end
  end
end
task :dependencies, [:conservative] => [ "dependencies:update", "dependencies:check" ]
