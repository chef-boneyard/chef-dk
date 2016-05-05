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

ACCEPTABLE_OUTDATED_GEMS = %w{
  celluloid
  celluloid-io
  docker-api
  fog-cloudatcost
  fog-google
  gherkin
  google-api-client
  jwt
  mime-types
  mini_portile2
  retriable
  rubocop
  slop
  timers
  unicode-display_width
  varia_model
}

require_relative "bundle_util"

namespace :dependencies do
  # Update all dependencies to the latest constraint-matching version
  task :update => "dependencies:update_omnibus_overrides" do
    extend BundleUtil
    puts ""
    puts "-------------------------------------------------------------------"
    puts "Updating Gemfile.lock ..."
    puts "-------------------------------------------------------------------"
    bundle "update", delete_gemfile_lock: true

    platforms.each do |platform|
      puts ""
      puts "-------------------------------------------------------------------"
      puts "Updating Gemfile.#{platform}.lock ..."
      puts "-------------------------------------------------------------------"
      bundle "lock --update", gemfile: "Gemfile.#{platform}", platform: platform, delete_gemfile_lock: true
    end

    puts ""
    puts "-------------------------------------------------------------------"
    puts "Updating omnibus/Gemfile.lock ..."
    puts "-------------------------------------------------------------------"
    bundle "update", cwd: "omnibus", delete_gemfile_lock: true
    # TODO make platform-specific locks for omnibus on windows, too

    puts ""
    puts "-------------------------------------------------------------------"
    puts "Updating omnibus/Berksfile.lock ..."
    puts "-------------------------------------------------------------------"
    File.delete("#{project_root}/omnibus/Berksfile.lock") if File.exist?("#{project_root}/omnibus/Berksfile.lock")
    bundle "exec berks install", cwd: "omnibus"

    puts ""
    puts "-------------------------------------------------------------------"
    puts "Updating acceptance/Gemfile.lock ..."
    puts "-------------------------------------------------------------------"
    bundle "update", cwd: "acceptance", delete_gemfile_lock: true
    # TODO make platform-specific locks for omnibus on windows, too
  end

  # Just like update, but only updates the minimum dependencies it can
  task :update_conservative do
    extend BundleUtil
    puts ""
    puts "-------------------------------------------------------------------"
    puts "Updating Gemfile.lock (conservatively) ..."
    puts "-------------------------------------------------------------------"
    bundle "install"

    platforms.each do |platform|
      puts ""
      puts "-------------------------------------------------------------------"
      puts "Updating Gemfile.#{platform}.lock (conservatively) ..."
      puts "-------------------------------------------------------------------"
      bundle "lock", gemfile: "Gemfile.#{platform}", platform: platform
    end

    puts ""
    puts "-------------------------------------------------------------------"
    puts "Updating omnibus/Gemfile.lock (conservatively) ..."
    puts "-------------------------------------------------------------------"
    bundle "install", cwd: "omnibus"
    # TODO make platform-specific locks for omnibus on windows, too

    puts ""
    puts "-------------------------------------------------------------------"
    puts "Updating omnibus/Berksfile.lock (conservatively) ..."
    puts "-------------------------------------------------------------------"
    bundle "exec berks install", cwd: "omnibus"

    puts ""
    puts "-------------------------------------------------------------------"
    puts "Updating acceptance/Gemfile.lock (conservatively) ..."
    puts "-------------------------------------------------------------------"
    bundle "install", cwd: "acceptance"
    # TODO make platform-specific locks for omnibus on windows, too
  end

  task :update_omnibus_overrides do
    puts ""
    puts "-------------------------------------------------------------------"
    puts "Updating omnibus/files/chef-dk-overrides.rb ..."
    puts "-------------------------------------------------------------------"
    # Get the latest bundler version
    overrides_path = File.expand_path("../../omnibus/files/chef-dk-overrides.rb", __FILE__)
    gem_list = `gem list -re bundler`
    gem_list =~ /bundler\s*\(([^)]*)\)/
    bundler_version = $1

    # Read the overrides file
    overrides = IO.read(overrides_path)

    # Replace the bundler version
    replaced = false
    overrides.sub!(/^(override\s+:bundler,\s*version:\s*")([^"]*)("\s*)$/) do
      replaced = true
      puts "bundler version: #{bundler_version} (was #{$2})"
      "#{$1}#{bundler_version}#{$3}"
    end
    raise "bundler version not found in overrides file!" unless replaced

    # Write the overrides file back out
    IO.write(overrides_path, overrides)
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
task :dependencies => [ "dependencies:update", "dependencies:check" ]
