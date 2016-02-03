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

require "vagrant-skytap/api/client"

shared_context "skytap" do
  Errors = VagrantPlugins::Skytap::Errors
  API = VagrantPlugins::Skytap::API

  let(:empty_action) {double(call: nil)}
  let(:ui)           {Vagrant::UI::Silent.new}

  def read_json(*args)
    JSON.load(File.read(File.join(args)))
  end

  # Bypass middleware actions, sort of, by stubbing the #call method
  def stub_actions(*action_names)
    if action_names.count == 1 && action_names.first.is_a?(Array)
      action_names = action_names.first
    end
    action_names.each do |name|
      classname = "VagrantPlugins::Skytap::Action::#{name}"
      stub_const(classname, double(classname, call: nil))
    end
  end
end
