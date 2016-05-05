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

  def gemfile_lock_task(task_name, dirs: [], other_platforms: true, leave_frozen: true)
    dirs.each do |dir|
      desc "Update #{dir}/Gemfile.lock. #{task_name}[conservative] to update as little as possible."
      task task_name, [:conservative] do |t, rake_args|
        extend BundleUtil
        conservative = rake_args[:conservative]
        puts ""
        puts "-------------------------------------------------------------------"
        puts "Updating #{dir}/Gemfile.lock#{conservative ? " (conservatively)" : ""} ..."
        puts "-------------------------------------------------------------------"
        with_bundle_unfrozen(cwd: dir, leave_frozen: leave_frozen) do
          bundle "install", cwd: dir, delete_gemfile_lock: !conservative
          if other_platforms
            # Include all other supported platforms into the lockfile as well
            platforms.each do |platform|
              bundle "lock", cwd: dir, platform: platform
            end
          end
        end
      end
    end
  end

  def berksfile_lock_task(task_name, dirs: [])
    dirs.each do |dir|
      desc "Update #{dir}/Berksfile.lock. #{task_name}[conservative] to update as little as possible."
      task task_name, [:conservative] do |t, rake_args|
        extend BundleUtil
        conservative = rake_args[:conservative]
        puts ""
        puts "-------------------------------------------------------------------"
        puts "Updating #{dir}/Berksfile.lock#{conservative ? " (conservatively)" : ""} ..."
        puts "-------------------------------------------------------------------"
        if !conservative && File.exist?("#{project_root}/#{dir}/Berksfile.lock")
          File.delete("#{project_root}/#{dir}/Berksfile.lock")
        end
        Dir.chdir("#{project_root}/#{dir}") do
          Bundler.with_clean_env do
            sh "bundle exec berks install"
          end
        end
      end
    end
  end

  gemfile_lock_task :update_omnibus_gemfile_lock, dirs: %w{omnibus}
  gemfile_lock_task :update_acceptance_gemfile_lock, dirs: %w{acceptance},
    other_platforms: false, leave_frozen: false

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
      puts "Getting latest chef 'stable' version from omnitruck ..."
      options = {
        channel: :stable,
        product_name: 'chef',
        product_version: :latest
      }
      version = Mixlib::Install.new(options).artifact_info.first.version

      # Modify the gemfile to pin to current chef
      gemfile_path = File.join(project_root, "Gemfile")
      gemfile = IO.read(gemfile_path)
      found = gemfile.sub!(/^(\s*gem "chef", github: "chef\/chef", branch: ")([^"]*)(")$/m) do
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

  desc "Update omnibus overrides, including versions in version_policy.rb and latest version of gems: #{OMNIBUS_RUBYGEMS_AT_LATEST_VERSION.keys}. update_omnibus_overrides[conservative] does nothing."
  task :update_omnibus_overrides, [:conservative] do |t, rake_args|
    conservative = rake_args[:conservative]
    unless conservative
      puts ""
      puts "-------------------------------------------------------------------"
      puts "Updating omnibus_overrides.rb ..."
      puts "-------------------------------------------------------------------"

      # Generate the new overrides file
      overrides = "# DO NOT EDIT. Generated by \"rake dependencies\". Edit version_policy.rb instead.\n"

      # Replace the bundler and rubygems versions
      OMNIBUS_RUBYGEMS_AT_LATEST_VERSION.each do |override_name, gem_name|
        # Get the latest bundler version
        puts "Running gem list -r #{gem_name} ..."
        gem_list = `gem list -r #{gem_name}`
        unless gem_list =~ /^#{gem_name}\s*\(([^)]*)\)$/
          raise "gem list -r #{gem_name} failed with output:\n#{gem_list}"
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
end
desc "Update all dependencies and check for outdated gems. Call dependencies[conservative] to update as little as possible."
task :dependencies, [:conservative] => [ "dependencies:update", "bundle:outdated" ]
task :update, [:conservative] => [ "dependencies:update", "bundle:outdated"]
