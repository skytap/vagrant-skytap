# Copyright (c) 2014-2016 Skytap, Inc.
#
# The MIT License (MIT)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

require "vagrant"

module VagrantPlugins
  module Skytap
    module Errors
      class VagrantSkytapError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_skytap.errors")
      end

      class InstanceReadyTimeout < VagrantSkytapError
        error_key(:instance_ready_timeout)
      end

      class RsyncError < VagrantSkytapError
        error_key(:rsync_error)
      end

      class MkdirError < VagrantSkytapError
        error_key(:mkdir_error)
      end

      class Unauthorized < VagrantSkytapError
        error_key(:unauthorized)
      end

      class DoesNotExist < VagrantSkytapError
        error_key(:does_not_exist)
      end

      class BadVmUrl < VagrantSkytapError
        error_key(:bad_vm_url)
      end

      class RegionMismatch < VagrantSkytapError
        error_key(:region_mismatch)
      end

      class ResourceBusy < VagrantSkytapError
        error_key(:resource_busy)
      end

      class RateLimited < VagrantSkytapError
        error_key(:rate_limited)
      end

      class UnprocessableEntity < VagrantSkytapError
        error_key(:unprocessable_entity)
      end

      class OperationFailed < VagrantSkytapError
        error_key(:operation_failed)
      end

      class VpnConnectionFailed < VagrantSkytapError
        error_key(:vpn_connection_failed)
      end

      class SourceVmNotStopped < VagrantSkytapError
        error_key(:source_vm_not_stopped)
      end

      class NotTemplateVm < VagrantSkytapError
        error_key(:not_template_vm)
      end

      class NoConnectionOptions < VagrantSkytapError
        error_key(:no_connection_options)
      end

      class FeatureNotSupportedForHostOs < VagrantSkytapError
        error_key(:feature_not_supported_for_host_os)
      end

      class VmParentMismatch < VagrantSkytapError
        error_key(:vm_parent_mismatch)
      end
    end
  end
end
