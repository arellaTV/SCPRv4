require "spec_helper"

describe ContentAsset do
  it { should belong_to :content }

  describe "asset" do
    it "finds the asset and returns it" do
      content_asset = build :asset
      content_asset.asset.should be_a AssetHost::Asset
    end

    it "Adds in a fallback caption if asset is a Fallback" do
      content_asset = build :asset
      content_asset.stub(:asset) { AssetHost::Asset::Fallback.new }
      content_asset.asset.caption.should match "We encountered a problem"
    end

    it "returns an external asset if there is one" do
      content_asset = build :asset
      external_asset = AssetHost::Asset::Fallback.new
      external_asset.json["title"] = "This is an external asset"
      content_asset.stub(:external_asset) { external_asset.json.to_json }
      content_asset.asset.title.should match "This is an external asset"
    end

    it "returns a fallback if an asset_id isn't present" do
      content_asset = build :asset
      content_asset.asset_id = nil
      content_asset.asset.caption.should match "We encountered a problem"
    end
  end
end
