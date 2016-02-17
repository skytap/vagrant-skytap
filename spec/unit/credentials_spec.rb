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

require_relative 'base'

describe VagrantPlugins::Skytap::API::Credentials do
  include_context "rest_api"

  let(:instance) { described_class.new(credential_attrs, nil, {}) }

  describe "recognized?" do
    subject { instance.recognized? }

    context "when text is xxx/yyy" do
      let(:credential_attrs) {{ "text" => "xxx/yyy" }}
      it { should be true }
    end

    context "when text is xxx / yyy" do
      let(:credential_attrs) {{ "text" => "xxx / yyy" }}
      it { should be true }
    end

    context "when text is blank" do
      let(:credential_attrs) {{ "text" => "" }}
      it { should be false }
    end

    context "when text is xxx, yyy" do
      let(:credential_attrs) {{ "text" => "xxx, yyy" }}
      it { should be false }
    end
  end
end
