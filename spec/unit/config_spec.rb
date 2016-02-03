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

require "vagrant-skytap/config"

describe VagrantPlugins::Skytap::Config do
  let(:instance) { described_class.new }

  # Ensure tests are not affected by Skytap credential environment variables
  before :each do
    ENV.stub(:[] => nil)
  end

  describe "defaults" do
    subject do
      instance.tap do |o|
        o.finalize!
      end
    end

    its("username")               { should be_nil }
    its("api_token")              { should be_nil }
    its("base_url")               { should == "https://cloud.skytap.com/" }
    its("vm_url")                 { should be_nil }
    its("vpn_url")                { should be_nil }
    its("instance_ready_timeout") { should == 120 }
    its("cpus")                   { should be_nil }
    its("cpuspersocket")          { should be_nil }
    its("ram")                    { should be_nil }
    its("guestos")                { should be_nil }
  end

  describe "overriding defaults" do
    [:username, :api_token, :base_url, :vm_url,
      :vpn_url, :instance_ready_timeout,
      :cpus, :cpuspersocket, :ram, :guestos].each do |attribute|
      it "should not default #{attribute} if overridden" do
        instance.send("#{attribute}=".to_sym, "foo")
        instance.finalize!
        instance.send(attribute).should == "foo"
      end
    end
  end

  describe "getting credentials from environment" do
    context "without Skytap credential environment variables" do
      subject do
        instance.tap do |o|
          o.finalize!
        end
      end

      its("username")  { should be_nil }
      its("api_token") { should be_nil }
    end

    context "with Skytap credential environment variables" do
      before :each do
        ENV.stub(:[]).with("VAGRANT_SKYTAP_USERNAME").and_return("username")
        ENV.stub(:[]).with("VAGRANT_SKYTAP_API_TOKEN").and_return("api_token")
      end

      subject do
        instance.tap do |o|
          o.finalize!
        end
      end

      its("username")  { should == "username" }
      its("api_token") { should == "api_token" }
    end
  end
end
