require "spec_helper"

describe Concern::Associations::AssetAssociation do
  describe '#assets' do
    it "orders by position" do
      content = build :test_class_story
      content.assets.to_sql.should match /order by position/i
    end

    it "tracks assets" do
      content = create :test_class_story
      asset = create :asset
      content.assets << asset
      content.save!
      content.versions.last.description.should match /Assets/
    end
  end

  describe '#asset' do
    it "gets the article's first asset" do
      content = create :test_class_story
      assets = create_list :asset, 2, content: content

      content.asset.should eq assets.first
    end

    it "uses a fallback if there are no assets" do
      content = create :test_class_story
      content.asset.should be_a AssetHost::Asset::Fallback
    end
  end


  describe '#asset_json' do
    it "uses simple_json for the asset" do
      record = create :test_class_story
      asset = create :asset, caption: "Hello", asset_id: 999, position: 4
      record.assets << asset
      record.save!

      record.asset_json.should eq [asset.simple_json].to_json
      record.assets.should eq [asset]
    end
  end

  #--------------------

  describe "#asset_json=" do
    context "create with asset_json passed in" do
      it "creates assets" do
        newrecord = create :test_class_story, asset_json: "[{\"id\":32459,\"caption\":\"Caption\",\"position\":12}]"
        newrecord.reload.assets.size.should eq 1
      end
    end

    it "doesn't do anything if passed-in argument is an empty string" do
      record = create :test_class_story
      record.asset_json = "[{\"id\":32459,\"caption\":\"Caption\",\"position\":12}]"
      record.assets.size.should eq 1

      record.asset_json = ""
      record.assets.size.should eq 1

      record.asset_json = "[]"
      record.assets.size.should eq 0
    end

    it "adds them ordered by position" do
      record = create :test_class_story
      record.asset_json = "[{\"id\":32459,\"caption\":\"Caption\",\"position\":12}, {\"id\":32458,\"caption\":\"Other Caption\",\"position\":0}]"
      record.assets.map(&:position).should eq [0, 12]
    end

    context "for new record" do
      it "parses the json and adds the asset" do
        record = build :test_class_story
        record.asset_json = "[{\"id\":32459,\"caption\":\"Caption\",\"position\":12}]"
        record.assets.size.should eq 1
        record.save!
        record.reload.assets.size.should eq 1
      end

      it "Doesn't create the association if run in a rollback transaction" do
        record = create :test_class_story
        record.assets.size.should eq 0

        record.transaction(requires_new: true) do
          record.asset_json = "[{\"id\":32459,\"caption\":\"Caption\",\"position\":12}]"
          record.assets.size.should eq 1
          raise ActiveRecord::Rollback
        end

        record.reload
        record.assets.size.should eq 0
      end
    end

    context "updating assets" do
      it "replaces the collection with the new one" do
        record = create :test_class_story
        record.asset_json = "[{\"id\":32459,\"caption\":\"Caption\",\"position\":12}]"
        record.assets.size.should eq 1
        record.save!

        record.asset_json = "[{\"id\":32450,\"caption\":\"Other Caption\",\"position\":1}]"
        record.assets.size.should eq 1
        record.assets.first.caption.should eq "Other Caption"
        record.save!

        # Make sure it actually deleted the other asset
        ContentAsset.count.should eq 1
      end
    end

    context "when no assets have changed" do
      it "doesn't set the assets" do
        original_json = "[{\"id\":32459,\"caption\":\"Caption\",\"position\":12}]"
        record = create :test_class_story, asset_json: original_json

        record.should_not_receive :assets=
        record.asset_json = original_json
      end
    end
  end

  describe '#asset_display' do
    it "returns the asset display if specified" do
      record = build :test_class_story,
        asset_display_id: ContentBase::ASSET_DISPLAY_IDS[:slideshow]

      record.asset_display.should eq :slideshow
    end

    it "returns nil if asset display not specified" do
      record = build :test_class_story, asset_display_id: nil
      record.asset_display.should eq nil
    end
  end

  describe '#asset_display=' do
    it "sets asset_display_id" do
      record = build :test_class_story, asset_display_id: nil
      record.asset_display = :photo_emphasized
      record.asset_display_id.should eq ContentBase::ASSET_DISPLAY_IDS[:photo_emphasized]
      record.asset_display.should eq :photo_emphasized
    end
  end

  describe "#mark_inline_assets" do 
    it "marks assets that are in the body as inline" do
      record = build :test_class_story, asset_json: "[{\"id\":32459,\"caption\":\"Caption\",\"position\":12}, {\"id\":32458,\"caption\":\"Other Caption\",\"position\":0}]"
      record.body = "
        <h2>Inline Assets Test</h2>
        <p>lorem ipsum</p>
        <img class=\"inline-asset\" data-asset-id=\"32459\" src=\"#\">
        <p>dolor sit amet</p>
      "
      expect(record.assets.map(&:inline).all?{|a| a == false}).to eq true
      record.mark_inline_assets
      expect(record.assets.select{|a| a.asset_id == 32459}.first.inline).to eq true
      expect(record.assets.select{|a| a.asset_id == 32458}.first.inline).to eq false
    end
  end

end
