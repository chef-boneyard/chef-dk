require 'semverse'
module ChefDK
  module Policyfile

    # TODO: tests.
    class CookbookSpec

      SOURCE_TYPES = [:git, :github, :path]

      attr_reader :version_constraint
      attr_reader :name
      attr_reader :source_options

      # TODO: maybe use keyword args?
      # (name, constraint=">= 0.0.0", git: nil, path: nil, github: nil)
      def initialize(name, version_constraint, source_options)
        @name = name
        @version_constraint = Semverse::Constraint.new(version_constraint)
        @source_options = source_options
        @source_type = SOURCE_TYPES.find { |type| source_options.key?(type) }
      end

      def ensure_cached
        installer.install # unless installer.installed?
      end

      def installer
        @installer ||= CookbookOmnifetch.init(self, source_options)
      end

      # TODO: this won't be true for community site or chef-server sourced cookbooks
      def version_fixed?
        true
      end

      def version
        cached_cookbook.version
      end

      def dependencies
        cached_cookbook.dependencies
      end

      def cached_cookbook
        installer.cached_cookbook
      end

    end
  end
end
