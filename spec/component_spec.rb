require File.dirname(__FILE__) + '/spec_helper'
require 'wee/component'

describe Wee::Component do
  before do
    @component = Wee::Component.new
  end
  subject {@component}
  context "when first created" do

    it "should have no children" do
      @component.children.should be_empty
    end

    it "should have no decoration" do
      @component.decoration.should == @component
    end
  end
  context "after adding components" do
    def create_child
      child = Object.new
      child
    end
    before do
      @children = (0..3).collect { create_child }
      @children.each {|child| @component << child }
    end
    it "should remember all added children" do
       subject.children.should == @children
    end
  end
  context "#add_decoration" do
    def create_decoration
      decoration = Object.new
      stub(decoration).global?.returns(false)
      stub(decoration, :next=)
      decoration
    end
    before do
      @decoration = create_decoration
    end
    subject do
      @component.add_decoration(@decoration)
      @component
    end
    it "should set the given decoration as the components decoration" do
      subject.decoration.should == @decoration
    end
    it "should set the component as owner of the decoration" do

    end
  end
end
