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

module ChefDK

  # Base class for errors raised by ChefDK::PolicyfileServices objects. Don't
  # raise this directly, create a descriptively-named subclass. You can rescue
  # this to catch all errors from PolicyfileServices objects though.
  class PolicyfileServiceError < StandardError
  end

  class PolicyfileNotFound < PolicyfileServiceError
  end

  class LockfileNotFound < PolicyfileServiceError
  end

  class PolicyfileInstallError < PolicyfileServiceError

    attr_reader :cause

    def initialize(message, cause)
      super(message)
      @cause = cause
    end

  end

  class PolicyfilePushError < PolicyfileServiceError

    attr_reader :cause

    def initialize(message, cause)
      super(message)
      @cause = cause
    end

  end

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

  class MissingComponentError < RuntimeError
    def initialize(component_name)
      super("Component #{component_name} is missing.")
    end
  end

  class OmnibusInstallNotFound < RuntimeError
    def initialize()
      super("Can not find omnibus installation directory for Chef.")
    end
  end

  class UnsupportedFeature < StandardError
  end

  class PolicyfileError < StandardError
  end

  class MissingCookbookLockData < StandardError
  end

  class InvalidLockfile < StandardError
  end

end
