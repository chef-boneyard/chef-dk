#
# Copyright:: Copyright (c) 2017 Chef Software Inc.
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

require "chef/mash"

module ChefDK
  module Policyfile
    class AttributeMergeChecker
      # A ConflictError is used to specify a conflict has occurred
      class ConflictError < StandardError
        attr_reader :attribute_path
        attr_reader :provided_by

        def initialize(attribute_path, provided_by)
          @attribute_path = attribute_path
          @provided_by = provided_by
          super("Attribute '#{attribute_path}' provided conflicting values by the following sources #{provided_by}")
        end
      end

      # A Leaf is used to mark an individual attribute that has already
      # been provided, along with its value and by who
      #
      # @api private
      class Leaf
        attr_reader :provided_by
        attr_reader :val

        def initialize(provided_by, val)
          @provided_by = provided_by
          @val = val
        end
      end

      # An AttributeHashInfo holds a set of attributes along with where they came from
      class AttributeHashInfo
        attr_reader :source_name
        attr_reader :hash
        def initialize(source_name, hash)
          @source_name = source_name
          @hash = hash
        end
      end

      # @return [Array<AttributeHashInfo>] A list of attributes and who they were provided by
      attr_reader :attribute_hash_infos

      def initialize
        @attribute_hash_infos = []
      end

      # Add a hash of attributes to the set of attributes that will be compared
      # for conflicts
      #
      # @param source_name [String] Where the attributes came from
      # @param hash [Hash] attributes from source_name
      def with_attributes(source_name, hash)
        attribute_hash_infos << AttributeHashInfo.new(source_name, hash)
      end

      # Check all added attributes for conflicts. Different sources can provide
      # the same attribute if they have the same value. Otherwise, it is considered
      # a conflict
      #
      # @raise ConflictError if there are conflicting attributes
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
