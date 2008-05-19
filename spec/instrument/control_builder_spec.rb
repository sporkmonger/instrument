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

describe Instrument::ControlBuilder do
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
end
