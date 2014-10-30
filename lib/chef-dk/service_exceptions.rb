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

##
# Exceptions for Service classes have more complex behaviors and more
# dependencies, so they are split into their own file here.
##

require 'chef-dk/service_exception_inspectors'

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

  class PolicyfileNestedException < PolicyfileServiceError

    attr_reader :cause
    attr_reader :inspector

    def initialize(message, cause)
      super(message)
      @inspector = inspector_for(cause)
      @cause = cause
    end

    def reason
      "(#{cause.class.name}) #{inspector.message}"
    end

    def extended_error_info
      inspector.extended_error_info
    end

    private

    def inspector_for(exception)
      if exception.respond_to?(:response)
        ServiceExceptionInspectors::HTTP.new(exception)
      else
        ServiceExceptionInspectors::Base.new(exception)
      end
    end

  end

  class PolicyfileInstallError < PolicyfileNestedException
  end

  class PolicyfilePushError < PolicyfileNestedException
  end

end

