require 'spec_helper'

def symbolize(klass)
  klass.to_s.underscore.to_sym
end

describe ContentBase do # Using news_story here arbitrarily
  describe "sorted_relations" do
    it "takes a list of frels and brels and returns an array of related records" do
      object = create :news_story, frel_count: 2, brel_count: 2
      sorted_relations = object.sorted_relations(object.frels.normal, object.brels.normal)
      sorted_relations.should include object.frels.first.content
      sorted_relations.should include object.brels.first.related
    end
    
    it "returns a blank array if there are no related objects" do
      object = create :news_story
      object.sorted_relations(object.frels.normal, object.brels.notiein).should eq []
    end
  end
  
  #---------------
  
  describe "classes" do
    before :each do
      content_classes = {
        content:  { "contentA"  => "ContentB" },
        other:    { "otherA"    => "OtherB" } 
      }
      
      stub_const("ContentBase::CONTENT_CLASSES", content_classes)
      stub_const("ContentB", "content B")
      stub_const("OtherB", "other B")
    end
    
    #---------------
    
    describe "content_classes" do
      it "returns only the content classes, constantized" do
        ContentBase.content_classes.should eq [ContentB]
      end
    end
  
    #---------------
  
    describe "other_classes" do
      it "returns only the other classes, constantized" do
        ContentBase.other_classes.should eq [OtherB]
      end
    end
  
    #---------------
  
    describe "all_classes" do
      it "returns all classes in the CONTENT_CLASSES constant, constantized" do
        ContentBase.all_classes.should eq [ContentB, OtherB]
      end
    end
  end
  
  #---------------
  
  describe "get_model_for_obj_key" do
    it "returns nil if key doesn't match anything" do
      ContentBase.get_model_for_obj_key("doesnt/match:123").should be_nil
    end
    
    it "returns the model constant if it does match" do
      stub_const("ContentBase::ALL_CLASSES", { "does/match" => "BlogEntry" } )
      ContentBase.get_model_for_obj_key("does/match:123").should eq BlogEntry
    end
  end
  
  #---------------
  
  describe "obj_by_key" do
    context "no match" do
      it "returns nil" do
        ContentBase.obj_by_key("nomatch").should be_nil
      end
    end
    
    context "match" do
      before :each do
        stub_const("ContentBase::ALL_CLASSES", { "blogs/entry" => "BlogEntry" } )
      end
      
      it "rescues with nil if there is a match but no record exists" do
        ContentBase.obj_by_key("blogs/entry:9999999").should be_nil
      end
    
      it "finds and returns the record if everything matches" do
        blog_entry = create :blog_entry
        ContentBase.should_receive(:find).and_return(blog_entry)
        ContentBase.obj_by_key("blogs/entry:#{blog_entry.id}").should eq blog_entry
      end
    end
  end
  
  #---------------
  
  describe "obj_by_url" do
    context "invalid URI" do
      it "returns nil" do
        ContentBase.obj_by_url("$$$$").should be_nil
      end
    end
    
    context "valid URI" do
      before :each do
        stub_const("ContentBase::CONTENT_MATCHES", {  %r{^/news/(\d+)/.*} => 'news/story' } )
        @url = "http://something.com/news/123/somethingelse/"
      end
      
      it "sends to obj_by_key if the URI matches" do
        ContentBase.should_receive(:obj_by_key).with("news/story:123").and_return("NewsStory")
        ContentBase.obj_by_url(@url).should eq "NewsStory"
      end
  
      it "returns nil if the URI doesn't match" do
        ContentBase.obj_by_url("http://nope.com/wrong").should be_nil
      end
    end
  end
end

# Basic functionality for ContentBase.content_classes
ContentBase.content_classes.each do |c|
  describe c do
    it "inherits from ContentBase" do
      object = build symbolize(c)
      object.should be_a ContentBase
    end
    
    it { should respond_to :headline }
    it { should respond_to :short_headline }
    it { should respond_to :body }
    it { should respond_to :teaser }
    it { should respond_to :link_path }
    it { should respond_to :remote_link_path }
    it { should respond_to :obj_key }
    it { should respond_to :auto_published_at }
    it { should respond_to :has_format? }
    it { should respond_to :byline_elements }
    
    it "must return byline_elements as an array" do
      object = build symbolize(c)
      object.byline_elements.should be_a Array
    end
    
    #-----------------
    
    describe "associations" do
      it { should have_many(:assets).class_name("ContentAsset").dependent(:destroy) }
      it { should have_one(:alarm).class_name("ContentAlarm").dependent(:destroy) }
      it { should have_many(:bylines).class_name("ContentByline").dependent(:destroy) }
      it { should have_many :brels }
      it { should have_many :frels }
      it { should have_many :related_links }
      it { should have_many :queries }
      it { should have_many :audio }
      it { should have_one :content_category }
      it { should have_one(:category).through(:content_category) }
    end

    #-----------------

    describe "validations" do
      unless ["ContentShell", "ShowEpisode"].include? c.model_name # ew
        it { should validate_presence_of(:slug) }
        it { should validate_format_of(:slug).with(%r{[\w-]+}) }
        
        it "validates slug uniqueness for date" do
          stub_publishing_callbacks(c)
          object = create symbolize(c), slug: "something"
          object2 = build symbolize(c), slug: "something" # different published_at
          object3 = build symbolize(c), slug: "something", published_at: object.published_at
          
          object2.should be_valid
          object3.should_not be_valid
          
          object3.errors.keys.should include :slug
        end
      end
    end
    
    #-----------------
    
    describe "publishing?" do
      it "returns true if status was changed and is now published" do
        object = build symbolize(c)
        object.stub(:status_changed?) { true }
        object.stub(:published?) { true }
        object.publishing?.should be_true
      end
      
      it "returns false if status was not changed" do
        object = build symbolize(c)
        object.stub(:status_changed?) { false }
        object.stub(:published?) { true }
        object.publishing?.should be_false
      end
      
      it "returns false if status is not published" do
        object = build symbolize(c)
        object.stub(:status_changed?) { true }
        object.stub(:published?) { false }
        object.publishing?.should be_false
      end
      
      it "returns false if status was not changed and status not published" do
        object = build symbolize(c)
        object.stub(:status_changed?) { false }
        object.stub(:published?) { false }
        object.publishing?.should be_false
      end
    end

    #-----------------

    describe "set_published_at_to_now" do
      it "sets published at to now" do
        object = build symbolize(c)
        time   = object.set_published_at_to_now
        object.published_at.should eq time
      end
    end

    #-----------------
        
    describe "callbacks" do
      it "runs set_published_at_to_now if publishing? is true" do
        object = build symbolize(c)
        object.stub(:publishing?) { true }
        object.should_receive :set_published_at_to_now
        object.save!
      end
      
      it "does not run set_published_at_to_now if publishing? is false" do
        object = build symbolize(c)
        object.stub(:publishing?) { false }
        object.should_not_receive :set_published_at_to_now
        object.save!
      end
    end
    
    #-----------------
    
    describe "#published" do
      it "returns an ActiveRecord::Relation" do
        create symbolize(c)
        c.published.class.should eq ActiveRecord::Relation
      end
      
      it "only selects published content" do
        published   = create_list symbolize(c), 3, :published
        unpublished = create_list symbolize(c), 2, :draft
        c.published.all.sort.should eq published.sort
      end
    end
    
    #-----------------
    
    describe "#link_path" do      
      it "accepts an options hash" do
        object = create symbolize(c)
        lambda { object.link_path(anchor: "comments") }.should_not raise_error
      end

      it "merges in an options hash unless it's a ContentShell" do
        object = create symbolize(c)
        if c == ContentShell
          object.link_path(anchor: "comments").should_not match "#comments"
        else  
          object.link_path(anchor: "comments").should match "#comments"
        end
      end
    end
    
    #-----------------
    
  end
end
