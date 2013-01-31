require 'spec_helper'

describe BlogEntry do  
  describe "associations" do
    describe "deleting tags" do
      before :each do
        @entry = build :blog_entry
        @tags = create_list :tag, 1
        @entry.tags = @tags
        @entry.save!
      end
      
      it "deletes tags in the join model when it's deleted" do
        TaggedContent.count.should eq 1
        @entry.destroy
        TaggedContent.count.should eq 0
      end
    
      it "doesn't delete the tag when the entry is deleted" do
        Tag.count.should eq 1
        @entry.destroy
        Tag.count.should eq 1
      end
    end
    
    describe "deleting categories" do
      before :each do
        @entry = build :blog_entry
        @blog_categories = create_list :blog_category, 1
        @entry.blog_categories = @blog_categories
        @entry.save!
      end
      
      it "deletes categories in the join model when it's deleted" do
        BlogEntryBlogCategory.count.should eq 1
        @entry.destroy
        BlogEntryBlogCategory.count.should eq 0
      end
    
      it "doesn't delete the category when the entry is deleted" do
        BlogCategory.count.should eq 1
        @entry.destroy
        BlogCategory.count.should eq 1
      end
    end
  end
  
  # ----------------
  
  describe "extended_teaser" do
    let(:entry) { create :blog_entry }
    
    it "returns a string" do
      entry.extended_teaser.should be_a String
    end
    
    it "includes paragraphs until the the target length is exceeded" do
      entry.body = "<p>Something</p><p>Something Else</p>"
      extended_teaser = entry.extended_teaser(2)
      extended_teaser.should match /^<p>Something/
      extended_teaser.should_not match /Something Else<\/p>$/
    end
    
    it "breaks if the class is story-break" do
      entry.body = "<p>Blah blah blah</p><br class='story-break' /><p>More Blah</p>"
      entry.extended_teaser.should_not match /More Blah/
    end
    
    it "appends a link to read more at the end, using the passed-in text" do
      entry.body = "<p>Something</p><p>Something Else</p>"
      extended_teaser = entry.extended_teaser(2, "Continue...")
      extended_teaser.should match "Continue..."
      extended_teaser.should match entry.link_path
    end
    
    it "ignores HTML tags when calculating the text length" do
      entry.body = "<p><a href='http://whatever.com'>Blah Blah Blah</a></p><p><strong>Bold Bold Bold</strong></p>"
      extended_teaser = entry.extended_teaser(20)
      extended_teaser.should match /Blah Blah Blah/
      extended_teaser.should match /Bold Bold Bold/
    end
  end
end
