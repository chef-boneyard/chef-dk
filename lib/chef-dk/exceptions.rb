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

module ChefDK

  class CachedCookbookNotFound < StandardError
  end

  class LocalCookbookNotFound < StandardError
  end

  class MalformedCookbook < StandardError
  end

  class DependencyConflict < StandardError
  end

  class CookbookNotInWorkingSet < DependencyConflict
  end

  class InvalidCookbookLockData < StandardError
  end

  class CachedCookbookModified < StandardError
  end

  class CookbookDoesNotContainRequiredRecipe < StandardError
  end

  class InvalidPolicyfileAttribute < StandardError
  end

  class MissingComponentError < RuntimeError
    def initialize(component_name, reason)
      super("Component #{component_name} is missing.\nReason: #{reason}")
    end
  end

  class OmnibusInstallNotFound < RuntimeError
    def initialize
      super("Can not find omnibus installation directory for Chef.")
    end
  end

  class UnsupportedFeature < StandardError
  end

  class PolicyfileError < StandardError
  end

  class InvalidPolicyfileSourceURI < StandardError
    def initialize(url, reason = nil)
      @url    = url
      @reason = reason
      msg     = "'#{@url}' is not a valid Policy File Source URI"
      msg << " #{@reason}." unless @reason.nil?
      super(msg)
    end
  end

  class MissingCookbookLockData < StandardError
  end

  class InvalidLockfile < StandardError
  end

  class InvalidPolicyfileFilename < StandardError
  end

  class InvalidUndoRecord < StandardError
  end

  class CantUndo < StandardError
  end

  class UndoRecordNotFound < StandardError
  end

  class MultipleErrors < StandardError
  end

  class BUG < RuntimeError
  end

  class IncludePolicyCookbookSourceConflict < StandardError
  end

  class CookbookSourceConflict < StandardError

    attr_reader :conflicting_cookbooks

    attr_reader :cookbook_sources

    def initialize(conflicting_cookbooks, cookbook_sources)
      @conflicting_cookbooks = conflicting_cookbooks
      @cookbook_sources      = cookbook_sources
      super(compute_message)
    end

    private

    def compute_message
      conflicting_cookbook_sets = cookbook_sources.combination(2).map do |source_a, source_b|
        overlapping_cookbooks = conflicting_cookbooks.select do |cookbook_name|
          source_a.universe_graph.key?(cookbook_name) && source_b.universe_graph.key?(cookbook_name)
        end
        "Source #{source_a.desc} and #{source_b.desc} contain conflicting cookbooks:\n" +
          overlapping_cookbooks.sort.map { |c| "- #{c}" }.join("\n") + "\n\n" +
          resolution_message(overlapping_cookbooks)
      end
      conflicting_cookbook_sets.join("\n")
    end

    def resolution_message(overlapping_cookbooks)
      example_source       = cookbook_sources.first
      source_key, location = example_source.default_source_args
      <<~EXAMPLE
        You can set a preferred source to resolve this issue with code like:

        default_source :#{source_key}, "#{location}" do |s|
          s.preferred_for "#{overlapping_cookbooks.join('", "')}"
        end
      EXAMPLE
    end

  end

  class PolicyfileLockDownloadError < StandardError
  end

  class LocalPolicyfileLockNotFound < StandardError
  end

  class InvalidPolicyfileLocation < StandardError
  end

end
