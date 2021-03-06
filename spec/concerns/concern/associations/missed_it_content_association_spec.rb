require 'spec_helper'

describe Concern::Associations::MissedItContentAssociation do
  before :each do
    @post = create :test_class_post, :published
    @bucket = create :missed_it_bucket
    @missed_it_content = create :missed_it_content, content: @post, missed_it_bucket: @bucket
    @bucket.content(true).should eq [@missed_it_content]
  end

  it "destroys the join record on destroy" do
    @post.destroy
    @bucket.content(true).should eq []
  end

  it "destroys the join record on unpublish" do
    @post.status = @post.class.status_id(:pending)
    @post.save!

    @bucket.content(true).should eq []
    @post.missed_it_contents(true).should eq []
  end

  it "doesn't destroy the join records on normal save" do
    @post.headline = "Updated"
    @post.save!

    @bucket.content(true).should eq [@missed_it_content]
    @post.missed_it_contents(true).should eq [@missed_it_content]
  end
end
