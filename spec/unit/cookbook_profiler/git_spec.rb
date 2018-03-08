#
# Copyright:: Copyright (c) 2014-2018 Chef Software Inc.
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

require "spec_helper"
require "shared/setup_git_cookbooks"
require "fileutils"
require "chef-dk/helpers"
require "chef-dk/cookbook_profiler/git"

describe ChefDK::CookbookProfiler::Git do

  include ChefDK::Helpers

  let(:git_profiler) do
    ChefDK::CookbookProfiler::Git.new(cookbook_path)
  end

  context "with cookbooks in a valid git repo" do

    include_context "setup git cookbooks"

    def edit_repo
      with_file(File.join(cookbook_path, "README.md"), "ab+") { |f| f.puts "some unpublished changes" }
    end

    context "given a clean repo with no remotes" do

      it "reports that the repo has no remotes" do
        expect(git_profiler.remote).to be_nil
      end

      it "determines the rev of the repo" do
        expect(git_profiler.revision).to eq(current_rev)
      end

      it "reports that the repo is clean" do
        expect(git_profiler.clean?).to be true
      end

      it "reports that the commits are unpublished" do
        expect(git_profiler.unpublished_commits?).to be true
      end

      it "reports that no remotes have the commits" do
        expect(git_profiler.synchronized_remotes).to eq([])
      end

    end

    context "when the remote is a local branch" do

      before do
        allow(git_profiler).to receive(:remote_name).and_return(".")
      end

      it "reports that the repo doesn't have a remote" do
        expect(git_profiler.have_remote?).to be(false)
      end

    end

    context "with a remote configured" do

      include_context "setup git cookbook remote"

      context "given a clean repo with all commits published to the remote" do

        it "determines the remote for the repo" do
          expect(git_profiler.remote).to eq(remote_url)
        end

        it "determines the rev of the repo" do
          expect(git_profiler.revision).to eq(current_rev)
        end

        it "reports that the repo is clean" do
          expect(git_profiler.clean?).to be true
        end

        it "reports that all commits are published to the upstream" do
          expect(git_profiler.unpublished_commits?).to be false
        end

        it "lists the remotes that commits are published to" do
          expect(git_profiler.synchronized_remotes).to eq(%w{origin/master})
        end

      end

      context "given a clean repo with unpublished changes" do

        before do
          edit_repo
          system_command('git config --local user.name "Alice"', cwd: cookbook_path).error!
          system_command('git config --local user.email "alice@example.com"', cwd: cookbook_path).error!
          system_command('git config --local commit.gpgsign "false"', cwd: cookbook_path).error!
          system_command('git commit -a -m "update readme" --author "Alice <alice@example.com>"', cwd: cookbook_path).error!
        end

        it "reports that the repo is clean" do
          expect(git_profiler.clean?).to be true
        end

        it "reports that there are unpublished changes" do
          expect(git_profiler.unpublished_commits?).to be true
        end

        it "reports that no remotes have the commits" do
          expect(git_profiler.synchronized_remotes).to eq([])
        end

      end
    end

    context "given a dirty repo" do

      before do
        edit_repo
      end

      it "reports that the repo is dirty" do
        expect(git_profiler.clean?).to be false
      end

    end

  end

  context "given a repo on an unborn master branch" do

    let(:cookbook_path) { File.join(tempdir, "unborn") }

    let(:profile_data) { git_profiler.profile_data }

    before do
      reset_tempdir
      FileUtils.mkdir_p(cookbook_path)
      system_command("git init .", cwd: cookbook_path).error!
    end

    it "does not error when profiling the cookbook" do
      expect { git_profiler.profile_data }.to_not raise_error
    end

    it "has a nil revision" do
      expect(profile_data["revision"]).to be_nil
    end

    it "has no remote" do
      expect(profile_data["remote"]).to be_nil
    end

    it "has no synchronized remote branches" do
      expect(profile_data["synchronized_remote_branches"]).to eq([])
    end

    it "is not published" do
      expect(profile_data["published"]).to be(false)
    end
  end

end
