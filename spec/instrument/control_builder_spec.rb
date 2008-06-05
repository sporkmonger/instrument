spec_dir = File.expand_path(File.join(File.dirname(__FILE__), ".."))
require File.join(spec_dir, "spec_helper")

class ImageControl < Instrument::Control
  def source
    return self.options[:source] || self.options[:src]
  end

  def alternate_text
    return self.options[:alternate_text] || self.options[:alt]
  end
end

# Verifies that Kernel#select isn't accidentally being called.
class Select < Instrument::Control
end

describe Instrument::ControlBuilder, "extending another object" do
  class ExtendedObject
    include Instrument::ControlBuilder
  end
  
  before :all do
    @extended_object = ExtendedObject.new
  end
  
  it "should enable mixins to function" do
    @extended_object.image_control.class.should == ImageControl
    @extended_object.select.class.should == Select
  end
  
  it "should still raise an Exception for non-existent methods" do
    (lambda do
      @extended_object.bogus
    end).should raise_error(NoMethodError)
  end
  
  it "should respond to a normal message" do
    @extended_object.should respond_to(:to_s)
  end
  
  it "should not respond to a bogus message" do
    @extended_object.should_not respond_to(:bogus)
  end
  
  it "should respond to a valid control name message" do
    @extended_object.should respond_to(:image_control)
  end
  
  it "should not respond to an invalid control name message" do
    @extended_object.should_not respond_to(:bogus_control)
  end
end
