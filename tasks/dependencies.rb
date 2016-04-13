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

require_relative "bundle_util"
require_relative "bundle"
require_relative "../version_policy"

desc "Tasks to update and check dependencies"
namespace :dependencies do
  # Update all dependencies to the latest constraint-matching version
  desc "Update all dependencies. dependencies:update[conservative] to update as little as possible."
  task :update, [:conservative] => %w{
                    dependencies:update_current_chef
                    dependencies:update_gemfile_lock
                    dependencies:update_omnibus_overrides
                    dependencies:update_omnibus_gemfile_lock
                    dependencies:update_acceptance_gemfile_lock
                    dependencies:update_omnibus_berksfile_lock
                  }

  desc "Update Gemfile.lock and all Gemfile.<platform>.locks. update_gemfile_lock[conservative] to update as little as possible."
  task :update_gemfile_lock, [:conservative] do |t, rake_args|
    conservative = rake_args[:conservative]
    if conservative
      Rake::Task["bundle:install"].invoke
    else
      Rake::Task["bundle:update"].invoke
    end
  end

  desc "Update omnibus/Gemfile.lock. update_omnibus_gemfile_lock[conservative] to update as little as possible."
  task :update_omnibus_gemfile_lock, [:conservative] do |t, rake_args|
    extend BundleUtil
    conservative = rake_args[:conservative]
    puts ""
    puts "-------------------------------------------------------------------"
    puts "Updating omnibus/Gemfile.lock#{conservative ? " (conservatively)" : ""} ..."
    puts "-------------------------------------------------------------------"
    bundle "install", cwd: "omnibus", delete_gemfile_lock: !conservative
  end

  desc "Update omnibus/Berksfile.lock. update_omnibus_berksfile_lock[conservative] to update as little as possible."
  task :update_omnibus_berksfile_lock, [:conservative] do |t, rake_args|
    extend BundleUtil
    conservative = rake_args[:conservative]
    puts ""
    puts "-------------------------------------------------------------------"
    puts "Updating omnibus/Berksfile.lock#{conservative ? " (conservatively)" : ""} ..."
    puts "-------------------------------------------------------------------"
    if !conservative && File.exist?("#{project_root}/omnibus/Berksfile.lock")
      File.delete("#{project_root}/omnibus/Berksfile.lock")
    end
    bundle "exec berks install", cwd: "omnibus"
  end

  desc "Update acceptance/Gemfile.lock (or one or more gems via update[gem1,gem2,...]). update_acceptance_gemfile_lock[conservative] to update as little as possible."
  task :update_acceptance_gemfile_lock, [:conservative] do |t, rake_args|
    extend BundleUtil
    conservative = rake_args[:conservative]
    puts ""
    puts "-------------------------------------------------------------------"
    puts "Updating acceptance/Gemfile.lock#{conservative ? " (conservatively)" : ""} ..."
    puts "-------------------------------------------------------------------"
    bundle "install", cwd: "acceptance", delete_gemfile_lock: !conservative
  end

  def latest_gem_version(gem_name)
    # Get the latest bundler version
    puts "Running gem list -r #{gem_name} ..."
    gem_list = `gem list -r #{gem_name}`
    unless gem_list =~ /^#{gem_name}\s*\((\S+).*\)$/
      raise "gem list -re #{gem_name} failed with output:\n#{gem_list}"
    end
    $1
  end

  desc "Update current chef release in Gemfile. update_current_chef[conservative] does nothing."
  task :update_current_chef, [:conservative] do |t, rake_args|
    extend BundleUtil
    conservative = rake_args[:conservative]
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
      current_version = Mixlib::Install.new(options).artifact_info.first.version

      # TODO in some edge cases, stable will actually be the latest chef because
      # promotion *moves* the package out of current into stable rather than
      # copying
      puts "Getting latest released chef gem ..."
      released_version = latest_gem_version("chef")
      if Gem::Version.new(released_version) >= Gem::Version.new(current_version)
        puts "The latest chef gem #{released_version} is more recent than the current channel chef release (#{current_version}). Using #{released_version} ..."
        gem_source = ""
        latest_version = released_version
      else
        puts "The current channel chef release #{current_version} is more recent than the latest chef gem #{released_version}. Using #{current_version} ..."
        gem_source = ", #{current_version.inspect}, github: \"chef/chef\", ref: \"v#{current_version.to_s}\""
        latest_version = current_version
      end

      # Modify the gemfile to pin to current chef
      gemfile_path = File.join(project_root, "Gemfile")
      gemfile = IO.read(gemfile_path)
      found = gemfile.sub!(/^(\s*gem\s+"chef")(.*)$/) do
        if gem_source != $2
          puts "Setting chef version in Gemfile to #{latest_version} (was #{$2.empty? ? "<latest>" : $2})"
        else
          puts "chef version in Gemfile already at latest (#{latest_version})"
        end
        "#{$1}#{gem_source}"
      end
      unless found
        raise "Gemfile does not have a line of the form 'gem \"chef\"', so we didn't update it to the latest (#{latest_version}). Remove dependencies:update_current_chef from the `dependencies:update` rake task to prevent it from being run if this is intentional."
      end

      if gemfile != IO.read(gemfile_path)
        puts "Writing modified #{gemfile_path} ..."
        IO.write(gemfile_path, gemfile)
      end
    end
  end

  desc "Update omnibus overrides, including versions in version_policy.rb and latest version of gems: #{OMNIBUS_RUBYGEMS_AT_LATEST_VERSION.keys}. update_omnibus_overrides[conservative] does nothing."
  task :update_omnibus_overrides, [:conservative] do |t, rake_args|
    conservative = rake_args[:conservative]
    unless conservative
      puts ""
      puts "-------------------------------------------------------------------"
      puts "Updating omnibus_overrides.rb ..."
      puts "-------------------------------------------------------------------"

      # Generate the new overrides file
      overrides = "# Generated by \"rake dependencies\". Do not edit.\n"

      # Replace the bundler and rubygems versions
      OMNIBUS_RUBYGEMS_AT_LATEST_VERSION.each do |override_name, gem_name|
        version = latest_gem_version(gem_name)

        # Emit it
        puts "Latest version of #{gem_name} is #{$version}"
        overrides << "override #{override_name.inspect}, version: #{$version.inspect}\n"
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
  desc "Check for gems that are not at the latest released version, and report if anything not in ACCEPTABLE_OUTDATED_GEMS (version_policy.rb) is out of date."
  task :check_outdated do
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
desc "Update all dependencies and check for outdated gems. Call dependencies[conservative] to update as little as possible."
task :dependencies, [:conservative] => [ "dependencies:update", "dependencies:check_outdated" ]
task :update, [:conservative] => [ "dependencies:update", "dependencies:check_outdated"]
