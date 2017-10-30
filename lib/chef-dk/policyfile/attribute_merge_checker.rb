require "chef/mash"
module ChefDK
  module Policyfile
    class AttributeMergeChecker
      class ConflictError < StandardError
        attr_reader :attribute_path
        attr_reader :provided_by

        def initialize(attribute_path, provided_by)
          @attribute_path = attribute_path
          @provided_by = provided_by
          super("Attribute '#{attribute_path}' provided conflicting values by the following sources #{provided_by}")
        end
      end

      class Leaf
        attr_reader :provided_by
        attr_reader :val

        def initialize(provided_by, val)
          @provided_by = provided_by
          @val = val
        end
      end

      class AttributeHashInfo
        attr_reader :source_name
        attr_reader :hash
        def initialize(source_name, hash)
          @source_name = source_name
          @hash = hash
        end
      end

      attr_reader :attribute_hash_infos

      def initialize
        @attribute_hash_infos = []
      end

      def with_attributes(source_name, hash)
        attribute_hash_infos << AttributeHashInfo.new(source_name, hash)
      end

      def check!
        check_struct = Mash.new
        attribute_hash_infos.each do |attr_hash_info|
          fill!(check_struct, attr_hash_info.source_name, "", attr_hash_info.hash)
        end
      end

      private

      def fill!(acc, source_name, path, hash)
        hash.each do |(key, val)|
          new_path = "#{path}[#{key}]"
          if val.kind_of?(Hash)
            acc[key] ||= Mash.new
            fill!(acc[key], source_name, new_path, val)
          else
            if acc[key].nil?
              acc[key] = Leaf.new(source_name, val)
            else
              leaf = acc[key]
              if leaf.val != val
                raise ConflictError.new(new_path, [leaf.provided_by, source_name])
              end
            end
          end
        end
      end

    end
  end
end
