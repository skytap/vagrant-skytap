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

require "tmpdir"
require "rubygems"

# Gems
require "checkpoint"
require "rspec/autorun"
require "webmock/rspec"

# Require Vagrant itself so we can reference the proper
# classes to test.
require "vagrant"
require "vagrant/util/platform"

require "vagrant-skytap"

# Add the test directory to the load path
$:.unshift File.expand_path("../../", __FILE__)

# Load in helpers
require "unit/support/shared/skytap_context"
require "unit/support/shared/rest_api_context"

# Do not buffer output
$stdout.sync = true
$stderr.sync = true

# Configure RSpec
RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true

  if Vagrant::Util::Platform.windows?
    c.filter_run_excluding :skip_windows
  else
    c.filter_run_excluding :windows
  end
end

# Configure VAGRANT_CWD so that the tests never find an actual
# Vagrantfile anywhere, or at least this minimizes those chances.
ENV["VAGRANT_CWD"] = Dir.mktmpdir("vagrant")

ENV["VAGRANT_DEFAULT_PROVIDER"] = "skytap"

# Unset all host plugins so that we aren't executing subprocess things
# to detect a host for every test.
Vagrant.plugin("2").manager.registered.dup.each do |plugin|
  if plugin.components.hosts.to_hash.length > 0
    Vagrant.plugin("2").manager.unregister(plugin)
  end
end

# Disable checkpoint
Checkpoint.disable!
