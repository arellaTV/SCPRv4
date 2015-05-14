require "spec_helper"

describe Concern::Associations::TagsAssociation do
  it "touches tags after save when publishing" do
    tag = FactoryGirl.create :tag
    tag.update_attributes updated_at: 1.month.ago, most_recent_at: nil, began_at: nil
    news_story = FactoryGirl.create :news_story
    news_story.update status: 0
    news_story.tags << tag
    news_story.update status: 5
    tag.reload.updated_at.should be > 1.month.ago
    tag.reload.most_recent_at.should_not be_nil
    tag.reload.began_at.should_not be_nil
  end
end
