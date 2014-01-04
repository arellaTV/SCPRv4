require "spec_helper"

describe Job::Index do
  subject { described_class }
  its(:queue) { should eq "scprv4:sphinx" }

  describe "::perform" do
    it "constantizes the arguments and passes it off to Indexer" do
      indexer = Indexer.new(BlogEntry)
      Indexer.should_receive(:new).with(BlogEntry).and_return(indexer)
      indexer.should_receive(:index)
      Job::Index.perform(["BlogEntry"])
    end
  end
end
