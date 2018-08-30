require "chef-dk/command/base"
require "chef-dk/ui"
require "chef-dk/cookbook_profiler/identifiers"

module ChefDK
  class IdDumper

    attr_reader :cb_path
    attr_reader :ui

    def initialize(ui, cb_relpath)
      @ui = ui
      @cb_path = cb_relpath
    end

    def run
      id = ChefDK::CookbookProfiler::Identifiers.new(cookbook_version)
      ui.msg "Path: #{cookbook_path}"
      ui.msg "SemVer version: #{id.semver_version}"
      ui.msg "Identifier: #{id.content_identifier}"
      ui.msg "File fingerprints:"
      ui.msg id.fingerprint_text
    end

    def cookbook_version
      @cookbook_version ||= cookbook_loader.cookbook_version
    end

    def cookbook_path
      File.expand_path(cb_path)
    end

    def cookbook_loader
      @cookbook_loader ||=
        begin
          loader = Chef::Cookbook::CookbookVersionLoader.new(cookbook_path, chefignore)
          loader.load!
          loader
        end
    end

    def chefignore
      @chefignore ||= Chef::Cookbook::Chefignore.new(File.join(cookbook_path, "chefignore"))
    end
  end

  module Command

    class DescribeCookbook < ChefDK::Command::Base

      banner "Usage: chef describe-cookbook <path/to/cookbook>"

      attr_reader :cookbook_path
      attr_reader :ui

      def initialize(*args)
        super
        @cookbook_path = nil
        @ui = UI.new
      end

      def run(params = [])
        return 1 unless apply_params!(params)
        return 1 unless check_cookbook_path
        IdDumper.new(ui, cookbook_path).run
      end

      def check_cookbook_path
        unless File.exist?(cookbook_path)
          ui.err("Given cookbook path '#{cookbook_path}' does not exist or is not readable")
          return false
        end

        md_path = File.join(cookbook_path, "metadata.rb")
        unless File.exist?(md_path)
          ui.err("Given cookbook path '#{cookbook_path}' does not appear to be a cookbook, it does not contain a metadata.rb")
          return false
        end
        true
      end

      def apply_params!(params)
        remaining_args = parse_options(params)
        if remaining_args.size != 1
          ui.err(opt_parser)
          return false
        else
          @cookbook_path = File.expand_path(remaining_args.first)
          true
        end
      end

    end
  end
end
