
require 'chef/cookbook_uploader'
# TODO: missing require in chef/cookbook_version
require 'chef/digester'
require 'chef/cookbook/cookbook_version_loader'

# TODO: FIX MONKEY PATCHING
class Chef
  class Cookbook
    class CookbookVersionLoader

      # CookbookVersionLoader is hardcoded to use the directory path as the
      # name, but we have oddly named directories. This problem could also be
      # solved by making chef require that metadata specify the cookbook name
      # (which should be happening eventually).
      attr_accessor :cookbook_name

    end
  end
end

module ChefDK
  class ReadCookbookForCompatModeUpload

    attr_reader :cookbook_name
    attr_reader :directory_path
    attr_reader :version_override

    def initialize(cookbook_name, version_override, directory_path)
      raise "TODO: TEST ME" unless $hax_mode
      @cookbook_name = cookbook_name
      @version_override = version_override
      @directory_path = directory_path

      @cookbook_version = nil
      @loader = nil
    end

    def cookbook_version
      raise "TODO: TEST ME" unless $hax_mode
      @cookbook_version ||=
        begin
          cookbook_version = loader.cookbook_version
          cookbook_version.version = version_override
          cookbook_version.freeze_version
          cookbook_version
        end
    end

    # TODO: handle chefignore
    def chefignore
      raise "TODO: TEST ME" unless $hax_mode
      nil
    end

    def loader
      raise "TODO: TEST ME" unless $hax_mode
      @loader ||=
        begin
          cbvl = Chef::Cookbook::CookbookVersionLoader.new(directory_path, chefignore)
          cbvl.cookbook_name = cookbook_name
          cbvl.load_cookbooks
          cbvl
        end
    end

  end

  class LockfileUploader

    # TODO: Fix API of CookbookUploader
    UNUSED_ARGUMENT = nil # :(

    attr_reader :policyfile_lock
    attr_reader :policy_group

    def initialize(policyfile_lock, policy_group)
      raise "TODO: TEST ME" unless $hax_mode
      @policyfile_lock = policyfile_lock
      @policy_group = policy_group
    end

    def upload
      raise "TODO: TEST ME" unless $hax_mode
      uploader.upload_cookbooks
      data_bag_create
      data_bag_item_create
    end

    def data_bag_create
      raise "TODO: TEST ME" unless $hax_mode
      Chef::DataBag.new.tap {|b| b.name("policyfiles") }.save
    end

    def data_bag_item_create
      raise "TODO: TEST ME" unless $hax_mode
      lock_data = policyfile_lock.to_lock
      lock_data["id"] = "#{policyfile_lock.name}-#{policy_group}"
      item = Chef::DataBagItem.new.tap do |i|
        i.data_bag("policyfiles")
        i.raw_data = lock_data
      end
      item.save
    end

    def uploader
      raise "TODO: TEST ME" unless $hax_mode
      @uploader ||= Chef::CookbookUploader.new(cookbook_versions_to_upload, UNUSED_ARGUMENT)
    end

    def cookbook_versions_to_upload
      raise "TODO: TEST ME" unless $hax_mode

      cookbook_versions_for_policy.reject do |cookbook|
        remote_already_has_cookbook?(cookbook)
      end
    end

    def remote_already_has_cookbook?(cookbook)
      return false unless existing_cookbook_on_remote.key?(cookbook.name.to_s)

      existing_cookbook_on_remote[cookbook.name.to_s]["versions"].any? do |cookbook_info|
        cookbook_info["version"] == cookbook.version
      end
    end

    def existing_cookbook_on_remote
      raise "TODO: TEST ME" unless $hax_mode
      @existing_cookbook_on_remote ||= Chef::CookbookVersion.list_all_versions
    end

    # An Array of Chef::CookbookVersion objects representing the full set that
    # the policyfile lock requires.
    def cookbook_versions_for_policy
      raise "TODO: TEST ME" unless $hax_mode
      policyfile_lock.validate_cookbooks!
      policyfile_lock.cookbook_locks.map do |name, lock|
        reader = ReadCookbookForCompatModeUpload.new(name, lock.dotted_decimal_identifier, lock.cookbook_path)
        reader.cookbook_version
      end
    end
  end
end
