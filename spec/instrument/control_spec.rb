spec_dir = File.expand_path(File.join(File.dirname(__FILE__), ".."))
require File.join(spec_dir, "spec_helper")

class SelectControl < Instrument::Control
  class Option
    def initialize(label, value)
      @label, @value = label, value
    end
    
    attr_accessor :label
    attr_accessor :value
  end
  
  def element_id
    return self.options[:id] || self.options[:name]
  end

  def element_name
    return self.options[:name]
  end
  
  def selections
    if !defined?(@selections) || @selections == nil
      @selections = []
      for selection in self.options[:selections]
        if selection.kind_of?(Hash)
          @selections << Option.new(selection[:label], selection[:value])
        else
          @selections << Option.new(selection, selection)
        end
      end
    end
    return @selections
  end
end

class SuperSelectControl < SelectControl
end

describe Instrument::Control do
  it "should be able to look up subclasses by name" do
    Instrument::Control.lookup("select_control").should ==
      SelectControl
    Instrument::Control.lookup("super_select_control").should ==
      SuperSelectControl
  end

  it "should have RAILS_ROOT/app/controls in the $CONTROL_PATH" do
    $CONTROL_PATH.should include(File.join(RAILS_ROOT, "app/controls"))
  end

  it "should not allow invalid types to be used" do
    (lambda do
      Instrument::Control.processor(:bogus)
    end).should raise_error(ArgumentError)
  end

  it "should initialize subclasses via method_missing" do
    Instrument::Control.new.select_control.class.should == SelectControl
  end

  it "should return the same options used during instantiation" do
    options = {}
    control = Instrument::Control.new(options)
    control.options.should eql(options)
  end

  it "should return the same proc used during instantiation" do
    proc = lambda {}
    control = Instrument::Control.new(&proc)
    control.block.should eql(proc)
  end
  
  it "should still raise an Exception for non-existent methods" do
    (lambda do
      Instrument::Control.new.bogus
    end).should raise_error(NoMethodError)
  end

  it "should raise an Exception for non-existent formats" do
    (lambda do
      SelectControl.new.to_bogus
    end).should raise_error(Instrument::ResourceNotFoundError)
  end

  it "should raise an Exception if a directory is found instead of a file" do
    (lambda do
      SelectControl.new.to_directory
    end).should raise_error(Instrument::ResourceNotFoundError)
  end

  it "should raise an Exception if a template engine is missing" do
    (lambda do
      SelectControl.new.to_txt
    end).should raise_error(Instrument::InvalidTemplateEngineError)
  end

  it "should raise an Exception if a template raises an Exception" do
    (lambda do
      SelectControl.new.to_xml
    end).should raise_error(ZeroDivisionError)
  end
end

describe Instrument::Control, "when rendered as XHTML with Haml" do
  before :all do
    @control = SelectControl.new(:name => "base", :selections => [
      "First", "Second", "Third", "Home"
    ])
    @xhtml = @control.to_xhtml
  end

  it "should have the correct id and name" do
    @xhtml.should match(/<select id="base" name="base">/)
  end
  
  it "should have options for all of the given selections" do
    @xhtml.should match(/<option value="First"/)
    @xhtml.should match(/<option value="Second"/)
    @xhtml.should match(/<option value="Third"/)
    @xhtml.should match(/<option value="Home"/)
  end
end

describe Instrument::Control, "when rendered as HTML with Markaby" do
  before :all do
    @control = SelectControl.new(:name => "base", :selections => [
      "First", "Second", "Third", "Home"
    ])
    @html = @control.to_html
  end

  it "should have the correct id and name" do
    # Ordering of attributes is indeterminate.
    @html.should match(/<select/)
    @html.should match(/id="base"/)
    @html.should match(/name="base"/)
  end
  
  it "should have options for all of the given selections" do
    @html.should match(/<option value="First"/)
    @html.should match(/<option value="Second"/)
    @html.should match(/<option value="Third"/)
    @html.should match(/<option value="Home"/)
  end
end

describe Instrument::Control, "when rendered as Atom with XML Builder" do
  before :all do
    @control = SelectControl.new(:name => "base", :selections => [
      "First", "Second", "Third", "Home"
    ])
    @atom = @control.to_atom
  end

  it "should have the correct id and name" do
    @atom.should match(/<title>Select Control<\/title>/)
  end
  
  it "should have options for all of the given selections" do
    @atom.should match(/<title>First<\/title>/)
    @atom.should match(/<title>Second<\/title>/)
    @atom.should match(/<title>Third<\/title>/)
    @atom.should match(/<title>Home<\/title>/)
  end
end

describe Instrument::Control, "when rendered as JSON with Erubis" do
  before :all do
    @control = SelectControl.new(:name => "base", :selections => [
      "First", "Second", "Third", "Home"
    ])
    @atom = @control.to_json
  end

  it "should have the correct id and name" do
    @atom.should match(/"id": "base"/)
    @atom.should match(/"name": "base"/)
  end
  
  it "should have options for all of the given selections" do
    @atom.should match(/"label": "First"/)
    @atom.should match(/"value": "First"/)
    @atom.should match(/"label": "Second"/)
    @atom.should match(/"value": "Second"/)
    @atom.should match(/"label": "Third"/)
    @atom.should match(/"value": "Third"/)
    @atom.should match(/"label": "Home"/)
    @atom.should match(/"value": "Home"/)
  end
end
