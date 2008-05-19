# ++
# Instrument, Copyright (c) 2008 Day Automation Systems, Inc.
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# --

require "instrument/control"

module Instrument
  # A module which you can mixin to allow for abbreviated control
  # creation.
  #
  # == Example
  #
  #   include Instrument::ControlBuilder
  #   
  #   select_control(:name => "base", :selections => [
  #     {:label => "One", :value => "1"},
  #     {:label => "Two", :value => "2"},
  #     {:label => "Three", :value => "3"},
  #     {:label => "Four", :value => "4"}
  #   ]).to_xhtml  
  module ControlBuilder
    ##
    # Prevents Kernel#select from being accidentally called.
    #
    #  @param [Array] params the method's parameters
    #  @param [Proc] block the block being passed to the method
    #  @return [Instrument::Control] the control being created
    def select(*params, &block) # :nodoc:
      return self.method_missing(:select, *params, &block)
    end

    ## 
    # Initializes Instrument::Control subclasses by name.
    # 
    #  @param [Symbol] method the method being called
    #  @param [Array] params the method's parameters
    #  @param [Proc] block the block being passed to the method
    #  @return [Instrument::Control] the control being created
    def method_missing(method, *params, &block)
      control_class = ::Instrument::Control.lookup(method.to_s)
      if control_class != nil
        return control_class.new(*params, &block)
      else
        raise NoMethodError,
          "undefined method `#{method}' for " +
          "#{self.inspect}:#{self.class.name}"
      end
    end    
  end
end
