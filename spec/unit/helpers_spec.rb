require "chef-dk/helpers"
class HelperTest
  include ChefDK::Helpers
end

describe HelperTest do

  describe "#habitat_install?" do
    after do
      ENV.delete("VIA_HABITAT")
    end
    context "when the environment variable VIA_HABITAT=='true'" do
      before do
        ENV["VIA_HABITAT"] = "true"
      end
      it "returns true" do
        expect(subject.habitat_install?).to eq true
      end
    end

    context "when the environment variable VIA_HABITAT is not 'true'" do
      before do
        ENV.delete("VIA_HABITAT")
      end

      it "returns false" do
        expect(subject.habitat_install?).to eq false
      end
    end
  end

  describe "#git_bin_dir" do
    context "when running from a habitat package" do
      let(:expected_git_bin_dir) { "/hab-path-to-git-bin-dir" }
      before do
        allow(subject).to receive(:habitat_install?).and_return true
        ENV["HAB_WS_GIT_BIN_DIR"] = expected_git_bin_dir
      end

      after do
        ENV.delete("HAB_WS_GIT_BIN_DIR")
      end

      it "provides a git path from the HAB_WS_GIT_BIN dir environment variable" do
        expect(subject.git_bin_dir).to eq expected_git_bin_dir
      end
    end

    context "when running from an omnibus package" do
      before do
        allow(subject).to receive(:habitat_install?).and_return false
      end
      it "should provide a path that references the gitbin directory" do
        expect(subject.git_bin_dir).to match(/.*#{File::SEPARATOR}gitbin.*/)
      end
    end
  end

  describe "#omnibus_env" do
    let(:omnibus_bin_dir) { "/omnibus-bin-dir" }
    let(:git_bin_dir) { "/dir/for/gitbin" }
    let(:habitat_bin_dir) { "/habitat-bin-dir" }
    let(:git_windows_bin_dir) { "C:\\gitbin" }
    let(:omnibus_embedded_bin_dir) { "/omnibus-embedded-bin-dir" }
    let(:habitat_embedded_bin_dir) { "/hab-embedded-bin-dir1:/hab-embedded-bin-dir2" }
    let(:env_path) { "/usr/bin:/bin" }
    let(:gem_user_dir) { File.expand_path("/home/user1/.gems") }
    let(:gem_default_dir) { "/gem/default/dir" }
    let(:gem_path) { ["/gem/path"] }
    before do
      allow(subject).to receive(:omnibus_bin_dir).and_return omnibus_bin_dir
      allow(subject).to receive(:habitat_bin_dir).and_return habitat_bin_dir
      allow(subject).to receive(:git_bin_dir).and_return git_bin_dir
      allow(subject).to receive(:git_windows_bin_dir).and_return git_windows_bin_dir
      allow(subject).to receive(:omnibus_embedded_bin_dir).and_return omnibus_embedded_bin_dir
      allow(subject).to receive(:habitat_embedded_bin_dir).and_return habitat_embedded_bin_dir
      allow(ENV).to receive(:[]).with("PATH").and_return env_path

      allow(Gem).to receive(:user_dir).and_return gem_user_dir
      allow(Gem).to receive(:default_dir).and_return gem_default_dir
      allow(Gem).to receive(:path).and_return gem_path
      allow(Dir).to receive(:exist?).with(git_bin_dir).and_return true
      allow(Dir).to receive(:exist?).with(git_windows_bin_dir).and_return true
    end

    context "when running from a habitat package" do
      before do
        allow(subject).to receive(:habitat_install?).and_return true
        allow(subject).to receive(:omnibus_install?).and_return false
      end
      it "provides an environment with habitat paths and no omnibus paths" do
        expected_path = [habitat_bin_dir,
                         File.join(gem_user_dir, "bin"),
                         habitat_embedded_bin_dir,
                         env_path].join(File::PATH_SEPARATOR)
        expected_env = {
          "GEM_HOME" => gem_user_dir,
          "GEM_PATH" => gem_path.join(File::PATH_SEPARATOR),
          "GEM_ROOT" => gem_default_dir,
          "PATH" => expected_path,
        }
        expect(subject.omnibus_env).to eq expected_env
      end
    end

    context "when running from an omnibus package" do
      before do
        allow(subject).to receive(:habitat_install?).and_return false
        allow(subject).to receive(:omnibus_install?).and_return true
      end
      it "provides an environment with omnibus paths and no habitat paths" do
        expected_path = [omnibus_bin_dir,
                         File.join(gem_user_dir, "bin"),
                         omnibus_embedded_bin_dir,
                         env_path,
                         git_bin_dir,
                         git_windows_bin_dir].join(File::PATH_SEPARATOR)

        expected_env = {
          "GEM_HOME" => gem_user_dir,
          "GEM_PATH" => gem_path.join(File::PATH_SEPARATOR),
          "GEM_ROOT" => gem_default_dir,
          "PATH" => expected_path,
        }

        expect(subject.omnibus_env).to eq expected_env
      end
    end

  end
end
