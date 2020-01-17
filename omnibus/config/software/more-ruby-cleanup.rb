#
# Copyright:: 2019 Chef Software, Inc.
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

require "fileutils"

name "more-ruby-cleanup"

skip_transitive_dependency_licensing true
license :project_license

source path: "#{project.files_path}/#{name}"

dependency "ruby"
dependency "rubygems"

build do
  block "Removing additional non-code files from installed gems" do
    # find the embedded ruby gems dir and clean it up for globbing
    target_dir = "#{install_dir}/embedded/lib/ruby/gems/*/gems".tr('\\', "/")
    files = %w{
      .github
      .kokoro
      Appraisals
      autotest/*
      bench
      benchmark
      benchmarks
      doc
      doc-api
      docs
      donate.png
      ed25519.png
      example
      examples
      ext
      frozen_old_spec
      Gemfile.devtools
      Gemfile.lock
      Gemfile.travis
      logo.png
      man
      rakelib
      release-script.txt
      sample
      samples
      site
      test
      tests
      travis_build_script.sh
      website
      yard-template
    }

    Dir.glob(Dir.glob("#{target_dir}/*/{#{files.join(",")}}")).each do |f|
      puts "Deleting #{f}"
      if File.directory?(f)
        # recursively removes files and the dir
        FileUtils.remove_dir(f)
      else
        File.delete(f)
      end
    end

    block "Removing spec dirs unless we're in components we test in the verify command" do
      # find the embedded ruby gems dir and clean it up for globbing
      target_dir = "#{install_dir}/embedded/lib/ruby/gems/*/gems".tr('\\', "/")

      Dir.glob(Dir.glob("#{target_dir}/*/spec")).each do |f|

        # don't delete these files if we use them in our verify tests
        unless File.basename(File.expand_path("..", f)).match?(/^(berkshelf|test-kitchen|chef|chef-dk|chef-apply|chefspec)-\d/)
          puts "Deleting unused spec dir #{f}"
          FileUtils.remove_dir(f)
        end
      end
    end
  end
end
