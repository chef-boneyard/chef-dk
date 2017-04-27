require "spec_helper"
require_relative "../../tasks/gemfile_util"

class GemfileSuper
  def gem(*args)
    :superclass
  end
end

class GemfileUtilUser < GemfileSuper
  include GemfileUtil
end

describe GemfileUtil do
  let (:gem_name) { "uncle_bobs_json_parser" }
  let (:gemfile_util) { GemfileUtilUser.new }

  context "#gem", :skip do
    it "calls the superclass method by default" do
      expect(gemfile_util).to receive(:gem).and_return(:superclass)
      gemfile_util.gem(gem_name)
    end

    # :path and :override follow the same code path, but for clarity get unrefactored specs.
    it "overrides gems with :path" do
      expect(gemfile_util).to receive(:warn_if_replacing)
      expect(gemfile_util.gem(gem_name, path: true)).to be_nil
      expect(gemfile_util.overridden_gems).to eq({ gem_name => [{ path: true }] })
    end

    it "overrides gems with :override" do
      expect(gemfile_util).to receive(:warn_if_replacing)
      expect(gemfile_util.gem(gem_name, override: true)).to be_nil
      expect(gemfile_util.overridden_gems).to eq({ gem_name => [{}] })
    end

    it "does not override gems with :overrideable" do
      expect(gemfile_util.gem(gem_name, override: true)).to be_nil
    end
  end
end
