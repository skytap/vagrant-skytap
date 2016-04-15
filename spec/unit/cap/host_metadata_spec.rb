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

require File.expand_path("../../base", __FILE__)
require "vagrant-skytap/cap/host_metadata"

describe VagrantPlugins::Skytap::Cap::HostMetadata do
  include_context "skytap"

  let(:machine)   { double(:machine) }
  let(:metadata)  { {"id" => 1, "configuration_url" => "foo"} }
  let(:metadata1) { metadata }
  let(:metadata2) { metadata }
  let(:status)    { 200 }
  let(:status1)   { status }
  let(:status2)   { status }

  before do
    stub_request(:any, /.*/).to_return(body: "", status: 404)
    stub_request(:get, "http://gw/skytap").to_return(body: JSON.dump(metadata1), status: status1)
    stub_request(:get, "http://169.254.169.254/skytap").to_return(body: JSON.dump(metadata2), status: status2)
  end

  def assert_fallback_to_ip
    expect(a_request(:get, "http://169.254.169.254/")).to have_been_made
  end

  def assert_no_fallback_to_ip
    expect(a_request(:get, "http://169.254.169.254/")).not_to have_been_made
  end

  describe "host_metadata" do
    subject do
      described_class.host_metadata(machine)
    end

    context "when default DNS is in use" do
      it "should get the metadata from gw" do
        expect(subject).to eq metadata
        assert_no_fallback_to_ip
      end

      context "when metadata service is down" do
        before do
          stub_request(:get, "http://gw/skytap").to_timeout
        end
        it "should raise an exception without retrying" do
          expect{subject}.to raise_error(Errors::MetadataServiceUnavailable)
          assert_no_fallback_to_ip
        end
      end

      context "when metadata service returns an error" do
        let(:status1) { 500 }
        it "should raise an exception without retrying" do
          expect{subject}.to raise_error(Errors::MetadataServiceUnavailable)
          assert_no_fallback_to_ip
        end
      end
    end

    context "when custom DNS is in use" do
      context "when gw resolves to some random web server" do
        let(:metadata1) { 'hello' }
        it "should fall back to the fixed IP address" do
          expect(subject).to eq metadata
          assert_fallback_to_ip
        end
      end

      context "when gw times out" do
        before do
          stub_request(:get, "http://gw/").to_timeout
        end
        it "should fall back to the fixed IP address" do
          expect(subject).to eq metadata
          assert_fallback_to_ip
        end
      end

      context "when gw cannot be resolved" do
        before do
          stub_request(:get, "http://gw/").to_raise(SocketError)
        end
        it "should fall back to the fixed IP address" do
          expect(subject).to eq metadata
          assert_fallback_to_ip
        end

        # Or maybe this isn't a Skytap VM.
        context "when fixed IP address is unreachable" do
          before do
            stub_request(:get, "http://169.254.169.254/").to_raise(Errno::ENETUNREACH)
          end
          it "should return nil" do
            expect(subject).to eq nil
            assert_fallback_to_ip
          end
        end
      end
    end
  end
end
