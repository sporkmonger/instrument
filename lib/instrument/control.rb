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
  ##
  # The Instrument::Control class provides a simple way to render nested
  # templates.
  #
  # == Example
  #
  #   select_control = SelectControl.new(:name => "base", :selections => [
  #     {:label => "One", :value => "1"},
  #     {:label => "Two", :value => "2"},
  #     {:label => "Three", :value => "3"},
  #     {:label => "Four", :value => "4"}
  #   ])
  #   xhtml_output = select_control.to_xhtml
  class Control
    ##
    # Registers a template type.  Takes a symbol naming the type, and a
    # block which takes a String as input and an Object to use as the
    # execution context and returns the rendered template output as a
    # String.  The block should ensure that all necessary libraries are
    # loaded.
    #
    #  @param [Array] type_list The template types being registered.
    #  @yield The block generates the template output.
    #  @yieldparam [String] input
    #    The template input.
    #  @yieldparam [Hash] options
    #    Additional parameters.
    #    :context - The execution context for the template, which will be set
    #      to the control object.
    #    :filename - The filename of the template being rendered.
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

    ##
    # Returns a list of registered template types.
    #
    #  @return [Array] a list of Symbols for the registered template types
    #  @see Instrument::Control.register_type
    def self.types
      if !defined?(@@type_map) || @@type_map == nil
        @@type_map = {}
      end
      return @@type_map.keys
    end

    ##
    # Returns the processor Proc for the specified type.
    #
    #  @param [Array] type_list the template types being registered
    #  @raise ArgumentError raises an error if the type is invalid.
    #  @return [Proc] the proc that handles template execution
    #  @see Instrument::Control.register_type
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

    ##
    # Registers subclasses with the Control base class.  Called automatically.
    #
    #  @param [Class] klass the subclass that is extending Control
    def self.inherited(klass)
      @@control_subclasses ||= []
      @@control_subclasses << klass
      @@control_subclasses.uniq!
      super
    end

    ##
    # Looks up a Control by name.
    #
    #  @param [String] control_name the control name of the Control
    #  @return [Instrument::Control, NilClass] the desired control or nil
    #  @see Instrument::Control.control_name
    def self.lookup(control_name)
      @@control_subclasses ||= []
      for control_subclass in @@control_subclasses
        if control_subclass.control_name == control_name
          return control_subclass
        end
      end
      return nil
    end

    ##
    # Creates a new Control object.  Subclasses should not override this.
    #
    #  @param [Hash] options a set of options required by the control
    #  @yield optionally accepts a block used by the control
    #  @return [Instrument::Control] the instanitated control
    def initialize(options={}, &block)
      @options = options
      @block = block
    end

    ##
    # Returns the options that were used to create the Control.
    #
    #  @return [Hash] a set of options required by the control
    attr_reader :options

    ##
    # Returns the block that was supplied when the Control was created.
    #
    #  @return [Proc] the block used to create the Control
    attr_reader :block

    ##
    # Returns the Control's name.  By default, this is the control's class
    # name, tranformed into   This method may be overridden by a Control.
    #
    #  @return [String] the control name
    def self.control_name
      return nil if self.name == "Instrument::Control"
      return self.name.
        gsub(/^.*::/, "").
        gsub(/([A-Z]+)([A-Z][a-z])/, "\\1_\\2").
        gsub(/([a-z\d])([A-Z])/, "\\1_\\2").
        tr("-", "_").
        downcase
    end

    ##
    # Returns a list of formats that this control may be rendered as.
    #
    #  @return [Array] the available formats
    def self.formats
      return [] if self.control_name == nil
      all_templates = []
      all_formats = []
      for load_path in $CONTROL_PATH
        full_name = File.expand_path(
          File.join(load_path, self.control_name))

        # Check to make sure the requested template is within the load path
        # to avoid inadvertent rendering of say, /etc/passwd
        next if full_name.index(File.expand_path(load_path)) != 0

        all_templates.concat(Dir.glob(full_name + ".*"))
      end
      for template in all_templates
        next if File.directory?(template)
        all_formats << template[/^.*\.([-_a-zA-Z0-9]+)\..*$/, 1]
      end
      return all_formats.uniq.reject { |f| f.nil? }
    end

    ##
    # Returns true if the control responds to the given message.
    #
    #  @return [Boolean] if the control responds
    def respond_to?(method, include_private=false)
      if method.to_s =~ /^to_/
        format = method.to_s.gsub(/^to_/, "")
        return self.class.formats.include?(format)
      else
        control_class = self.class.lookup(method.to_s)
        if control_class != nil
          return true
        else
          if options[:delegate] != nil &&
              options[:delegate].respond_to?(method)
            return true
          end
        end
      end
      super
    end

    ##
    # Relays to_format messages to the render method.
    #
    #  @param [Symbol] method the method being called
    #  @param [Array] params the method's parameters
    #  @param [Proc] block the block being passed to the method
    #  @return [Object] the return value
    #  @raise NoMethodError if the method wasn't handled
    #  @see Instrument::Control#render
    def method_missing(method, *params, &block)
      if method.to_s =~ /^to_/
        format = method.to_s.gsub(/^to_/, "")
        self.render(format, *params, &block)
      else
        control_class = self.class.lookup(method.to_s)
        if control_class != nil
          control_class.new(*params, &block)
        else
          if options[:delegate] != nil &&
              options[:delegate].respond_to?(method)
            options[:delegate].send(method, *params, &block)
          else
            raise NoMethodError,
              "undefined method `#{method}' for " +
              "#{self.inspect}:#{self.class.name}"
          end
        end
      end
    end

    ##
    # Renders a control in a specific format.
    #
    #  @param [String] format the format name for the template output
    #  @return [String] the rendered output in the desired format
    #  @raise Instrument::ResourceNotFoundError if the template is missing
    #  @raise Instrument::InvalidTemplateEngineError if type isn't registered
    def render(format)
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
        return self.class.processor(type).call(
          raw_content, {:context => self, :filename => path}
        )
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
Instrument::Control.register_type(:haml) do |input, options|
  require "haml"
  context = options[:context]
  filename = options[:filename]
  Haml::Engine.new(
    input, :attr_wrapper => "\"", :filename => filename
  ).render(context)
end
Instrument::Control.register_type(:erb, :rhtml) do |input, options|
  begin; require "erubis"; rescue LoadError; require "erb"; end
  context = options[:context]
  filename = options[:filename]
  binding = context.instance_eval { (lambda {}).binding }
  erb = Erubis::Eruby.new(input) rescue ERB.new(input)
  if erb.respond_to?(:filename=)
    erb.filename = filename
  end
  erb.result(binding)
end
Instrument::Control.register_type(:mab) do |input, options|
  require "markaby"
  context = options[:context]
  Markaby::Builder.new({}, context).capture do
    eval(input)
  end
end
Instrument::Control.register_type(:rxml) do |input, options|
  require "builder"
  context = options[:context]
  xml = Builder::XmlMarkup.new(:indent => 2)
  binding = context.instance_eval { (lambda {}).binding }
  eval(input, binding)
end
