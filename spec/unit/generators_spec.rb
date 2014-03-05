#
# Copyright:: Copyright (c) 2014 Chef Software Inc.
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

require 'spec_helper'
require 'fileutils'
require 'chef-dk/generators'

describe ChefDK::Generators::Tree do

  let(:specs_tmpdir) { File.expand_path("../specs-tmpdir", fixtures_path) }

  let(:source_skeleton) { File.join(fixtures_path, "generator-skeletons/example-tree") }
  let(:destination) { File.expand_path("../specs-tmpdir/tree-generator-test", fixtures_path) }
  subject(:generator) { ChefDK::Generators::Tree.new(source_skeleton, destination) }

  let(:skeleton_file_relpaths) do
    # find spec/unit/fixtures/generator-skeletons -type f
    %w[
      spec/unit/fixtures/generator-skeletons/example-tree/.a_static_dotfile
      spec/unit/fixtures/generator-skeletons/example-tree/.a_template_dotfile.erb
      spec/unit/fixtures/generator-skeletons/example-tree/a_static_file.txt
      spec/unit/fixtures/generator-skeletons/example-tree/directory/COOKBOOK_NAME/a_static_file_in_a_dynamic_dir.txt
      spec/unit/fixtures/generator-skeletons/example-tree/directory/nested_static_file.txt
      spec/unit/fixtures/generator-skeletons/example-tree/directory/nested_templated_file.txt.erb
      spec/unit/fixtures/generator-skeletons/example-tree/license_txt.erb
      spec/unit/fixtures/generator-skeletons/example-tree/metadata.rb.erb
    ]
  end

  let(:skeleton_dir_relpaths) do
    # find spec/unit/fixtures/generator-skeletons/example-tree -type d 
    %w[
        spec/unit/fixtures/generator-skeletons/example-tree/directory
        spec/unit/fixtures/generator-skeletons/example-tree/directory/COOKBOOK_NAME
    ]
  end

  let(:skeleton_files) do
    skeleton_file_relpaths.map { |p| File.join(project_root, p) }
  end

  let(:skeleton_dirs) do
    
  end

  before do
    FileUtils.rm_rf(specs_tmpdir) if File.exist?(specs_tmpdir)
    FileUtils.mkdir_p(specs_tmpdir)
  end

  it "lists the files in the skeleton" do
    expect(generator.skeleton_files).to match_array(skeleton_files)
  end

end
