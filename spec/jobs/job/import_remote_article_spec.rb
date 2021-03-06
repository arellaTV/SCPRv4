require 'spec_helper'

describe Job::ImportRemoteArticle do
  subject { described_class }
  it { subject.queue.should eq Job::QUEUES[:high_priority] }

  before :each do
    stub_request(:get, %r|api\.npr|).to_return({
      :headers => {
        :content_type   => "application/json"
      },
      :body => load_fixture('api/npr/story.json')
    })
  end

  it "raises an error if the story isn't found" do
    article = create :npr_article, headline: "Four Men In A Small Boat Face The Northwest Passage"
    RemoteArticle.any_instance.stub(:import)

    expect { Job::ImportRemoteArticle.perform(article.id, "NewsStory") }.to raise_error
  end
end
