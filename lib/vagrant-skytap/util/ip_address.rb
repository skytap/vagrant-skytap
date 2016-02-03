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

module VagrantPlugins
  module Skytap
    module Util
      class IpAddress
        class InvalidIp < RuntimeError; end
        IP_REGEX = /^(0[0-7]*|0[x][0-9a-f]+|[1-9][0-9]*)\.(0[0-7]*|0[x][0-9a-f]+|[1-9][0-9]*)\.(0[0-7]*|0[x][0-9a-f]+|[1-9][0-9]*)\.(0[0-7]*|0[x][0-9a-f]+|[1-9][0-9]*)$/i
        MAX_IP4_INT = 2**32 - 1

        class << self
          def str_to_int(str)
            raise InvalidIp.new("'#{str}' does not look like an IP") unless str =~ IP_REGEX
            bytes = [Integer($1), Integer($2), Integer($3), Integer($4)]
            raise InvalidIp.new("'#{str}' octet exceeds 255") if bytes.any?{|b| b > 255}
            bytes.zip([24, 16, 8, 0]).collect{|n,shift| n << shift}.inject(&:+)
          end
          def int_to_str(i)
            raise InvalidIp.new("#{i} exceeds maximum IPv4 address") if i > MAX_IP4_INT
            [24, 16, 8, 0].collect{|shift| (i & (255 << shift)) >> shift}.join('.')
          end
        end

        def initialize(str_or_int)
          if str_or_int.is_a?(String)
            @i = self.class.str_to_int(str_or_int)
          elsif str_or_int.is_a?(Integer)
            raise InvalidIp.new("IP #{str_or_int} is greater than the maximum IPv4 value") if str_or_int > MAX_IP4_INT
            raise InvalidIp.new("IP value must be non-negative")  if str_or_int < 0
            @i = str_or_int
          else
            raise InvalidIp.new("Don't know how to make an IP out of #{str_or_int}")
          end
        end

        def to_i
          @i
        end

        def to_s
          self.class.int_to_str(@i)
        end

        MAX_IP4 = self.new(MAX_IP4_INT)

        # IpAddress arithmetic ops result in new IP addresses
        [:+, :-, :&, :|, :<<, :>>].each do |name|
          define_method(name) do |other|
            IpAddress.new(@i.send(name, other.to_i))
          end
        end

        # IpAddress comparisons just proxy to the .to_i value
        [:==, :<, :>, :>=, :<=, :<=>].each do |name|
          define_method(name) do |other|
            @i.send(name, other.to_i)
          end
        end

        def inverse
          MAX_IP4 - self
        end
        alias_method :~, :inverse

        def succ
          self + 1
        end
      end
    end
  end
end
