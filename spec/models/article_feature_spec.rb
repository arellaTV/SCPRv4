require 'spec_helper'

describe ArticleFeature do
  describe '::find_by_id' do
    after :each do
      ArticleFeature.collection = FEATURES
    end

    it 'retrieves the feature by a given ID' do
      feature = ArticleFeature.new(id: 12345, key: :lasagna)
      ArticleFeature.collection << feature
      ArticleFeature.find_by_id(12345).should eq feature
    end

    it "is nil if no feature is found" do
      ArticleFeature.find_by_id(-200).should be_nil
    end
  end

  describe '::find_by_key' do
    after :each do
      ArticleFeature.collection = FEATURES
    end

    it 'retrieves the feature by a given ID' do
      feature = ArticleFeature.new(key: :test_feature)
      ArticleFeature.collection << feature
      ArticleFeature.find_by_key(:test_feature).should eq feature
    end

    it "is nil if no feature is found" do
      ArticleFeature.find_by_key(:watwatwatwatwat).should be_nil
    end

  end

  describe 'attributes' do
    it "sets id" do
      ArticleFeature.new(id: 1, key: :lasagna).id.should eq 1
    end

    it "sets key" do
      ArticleFeature.new(key: :hello).key.should eq :hello
    end

    it "sets name" do
      ArticleFeature.new(name: "Hi", key: :lasagna).name.should eq "Hi"
    end

    it "sets asset display" do
      ArticleFeature.new(asset_display: "hidden", key: :lasagna)
        .asset_display.should eq "hidden"
    end
  end

  describe '#==' do
    it "compares integers" do
      feature = ArticleFeature.new(id: 123, key: :lasagna)
      (feature == 123).should be_true
    end

    it "compares article features" do
      feature = ArticleFeature.new(id: 456, key: :lasagna)
      (feature == feature).should be_true
    end

    it "compares keys" do
      feature = ArticleFeature.new(key: :yo)
      (feature == :yo).should be_true
    end
  end
end
