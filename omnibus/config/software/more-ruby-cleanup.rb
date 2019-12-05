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
      examples
      example
      docs
      doc
      doc-api
      sample
      samples
      test
      tests
      benchmark
      benchmarks
      rakelib
      CHANGELOG.md
      CONTRIBUTORS.md
      README.md
      README.markdown
      HISTORY.md
      TODO.md
      CONTRIBUTING.md
      ISSUE_TEMPLATE.md
      UPGRADING.md
      CODE_OF_CONDUCT.md
      Code-of-Conduct.md
      ARCHITECTURE.md
      CHANGES.md
      README.YARD.md
      GUIDE.md
      MIGRATING.md
      README.txt
      HISTORY.txt
      Manifest.txt
      Manifest
      CHANGES.txt
      CHANGELOG.txt
      FAQ.txt
      release-script.txt
      TODO
      HISTORY
      CHANGES
      CHANGELOG
      README
      README-json-jruby.md
      Gemfile.travis
      Gemfile.lock
      Gemfile.devtools
      README.rdoc
      CHANGELOG.rdoc
      History.rdoc
      CONTRIBUTING.rdoc
      README_INDEX.rdoc
      logo.png
      donate.png
      Appraisals
      website
      man
      site
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
  end
end
