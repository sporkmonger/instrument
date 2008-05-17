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

require "instrument/version"
require "instrument/errors"

# This variable stores a list of all paths to search for when locating a
# named control.
$CONTROL_PATH = ["."]
if defined?(RAILS_ROOT)
  $CONTROL_PATH.unshift(File.join(RAILS_ROOT, "app/controls"))
end

module Instrument
  # The Instrument::Control class provides a simple way to render nested
  # templates.
  class Control
    # Registers a template type.  Takes a symbol naming the type, and a
    # block which takes a String as input and an Object to use as the
    # execution context and returns the rendered template output as a
    # String.  The block should ensure that all necessary libraries are
    # loaded.
    def self.register_type(*type_list, &block)
      # Ensure the @@type_map is initialized.
      self.types
      
      for type in type_list
        # Normalize to symbol
        type = type.to_s.to_sym
        @@type_map[type] = block
      end
      return nil
    end
    
    # Returns a list of registered template types.
    def self.types
      if !defined?(@@type_map) || @@type_map == nil
        @@type_map = {}
      end
      return @@type_map.keys
    end

    # Returns the processor Proc for the specified type.
    #
    # Raises an ArgumentError if the type is invalid.
    def self.processor(type)
      # Normalize to symbol
      type = type.to_s.to_sym

      if !self.types.include?(type)
        raise ArgumentError,
          "Unrecognized template type: #{type.inspect}\n" +
          "Valid types: " +
          "#{(self.types.map {|t| t.inspect}).join(", ")}"
      end

      return @@type_map[type]
    end
    
    # Registers subclasses with the Control base class.
    def self.inherited(klass)
      if !defined?(@@control_subclasses) || @@control_subclasses == nil
        @@control_subclasses = []
      end
      @@control_subclasses << klass
      @@control_subclasses.uniq!
    end
    
    # Looks up a Control by name.
    def self.lookup(control_name)
      for control_subclass in (@@control_subclasses || [])
        if control_subclass.control_name == control_name
          return control_subclass
        end
      end
      return nil
    end
    
    # Creates a new Control object.
    def initialize(options={})
      @options = options
    end
    
    # Returns the options that were used to create the Control.
    attr_reader :options
    
    # Returns the Control's name.  By default, this is the Control's
    # class name, downcased, without the Control suffix.  This method
    # may be overridden by a Control.
    def self.control_name
      return "base" if self.name == "Instrument::Control"
      return self.name.gsub(/^.*::/, "").gsub(/Control$/, "").downcase
    end
    
    # Relays to_format messages to the render method.
    def method_missing(method, *params, &block)
      if method.to_s =~ /^to_/
        format = method.to_s.gsub(/^to_/, "")
        self.send(:render, format, *params, &block)
      else
        control_class = self.class.lookup(method.to_s)
        if control_class != nil
          control_class.new(*params, &block)
        else
          raise NoMethodError,
            "undefined method `#{method}' for " +
            "#{self.inspect}:#{self.class.name}"
        end
      end
    end
    
    # Renders a control in a specific format.
    def render(format, options={})
      # Locate the template.
      path = nil
      for load_path in $CONTROL_PATH
        full_name = File.expand_path(
          File.join(load_path, self.class.control_name))

        # Check to make sure the requested template is within the load path
        # to avoid inadvertent rendering of say, /etc/passwd
        next if full_name.index(File.expand_path(load_path)) != 0

        templates = Dir.glob(full_name + ".#{format}.*")
        
        # Select the first template matched.  If there's more than one,
        # the extras will be ignored.
        template = templates.first
        if template != nil
          path = template
          break
        end
      end

      if path == nil
        raise Instrument::ResourceNotFoundError,
          "Template not found: '#{self.class.control_name}.#{format}.*'"
      elsif File.directory?(path)
        raise Instrument::ResourceNotFoundError,
          "Template not found: '#{self.class.control_name}.#{format}.*'"
      end

      # Normalize to symbol
      type = File.extname(path).gsub(/^\./, "").to_s
      if type != "" && !self.class.types.include?(type.to_sym)
        raise Instrument::InvalidTemplateEngineError,
          "Unrecognized template type: #{type.inspect}\n" +
          "Valid types: [" +
          "#{(self.class.types.map {|t| t.inspect}).join(", ")}]"
      end
      raw_content = File.open(path, "r") do |file|
        file.read
      end

      begin
        return self.class.processor(type).call(raw_content, self)
      rescue Exception => e
        e.message <<
          "\nError occurred while rendering " +
          "'#{self.class.control_name}.#{format}.#{type}'"
        raise e
      end
    end
  end
end

# Register the default types.
Instrument::Control.register_type(:haml) do |input, context|
  require "haml"
  Haml::Engine.new(input, {:attr_wrapper => "\""}).render(context)
end
Instrument::Control.register_type(:erb, :rhtml) do |input, context|
  begin; require "erubis"; rescue LoadError; require "erb"; end
  erb = Erubis::Eruby.new(input) rescue ERB.new(input)
  erb.result(context.send(:binding))
end
Instrument::Control.register_type(:mab) do |input, context|
  require "markaby"
  Markaby::Builder.new({}, context).capture do
    eval(input)
  end
end
Instrument::Control.register_type(:rxml) do |input, context|
  require "builder"
  xml = Builder::XmlMarkup.new(:indent => 2)
  eval(input, context.send(:binding))
end
