require "spec_helper"

describe ExternalProgram do
  describe "scopes" do
    describe "active" do
      it "selects programs with online or onair status" do
        onair   = create :external_program, :from_rss, air_status: "onair"
        online  = create :external_program, :from_rss, air_status: "online"
        hidden  = create :external_program, :from_rss, air_status: "hidden"
        ExternalProgram.active.sort.should eq [onair, online].sort
      end
    end
  end

  describe '::sync' do
    before :each do
      stub_request(:get, %r{podcast\.com}).to_return({
        :headers => {
          :content_type   => "text/xml"
        },
        :body           => load_fixture('rss/rss_feed.xml')
      })
    end

    it "syncs the programs" do
      program = create :external_program, :from_rss, podcast_url: "http://podcast.com/podcast"
      Job::SyncExternalPrograms.perform
      program.episodes.should_not be_empty
    end
  end

  #-----------------

  describe '#published?' do
    it "is true if air_status is not hidden" do
      onair   = build :external_program, :from_rss, air_status: "onair"
      online  = build :external_program, :from_rss, air_status: "online"

      onair.published?.should eq true
      online.published?.should eq true
    end

    it "is false if air_status is hidden" do
      hidden = build :external_program, :from_rss, air_status: "hidden"
      hidden.published?.should eq false
    end
  end

  describe '#importer' do
    it 'is the importer class based on source' do
      program = build :external_program, :from_npr
      program.importer.should eq NprProgramImporter
    end
  end

  describe '#sync' do
    context 'for npr' do
      before :each do
        stub_request(:get, %r{api\.npr\.org}).to_return({
          :headers => {
            :content_type   => "application/json"
          },
          :body           => load_fixture('api/npr/program.json')
        })
      end

      it "syncs using the importer" do
        program = create :external_program, :from_npr
        program.sync
        program.episodes.should_not be_empty
        program.segments.should_not be_empty
      end
    end

    context 'for rss' do
      before :each do
        stub_request(:get, %r{rss\.com}).to_return({
          :headers => {
            :content_type   => "text/xml"
          },
          :body           => load_fixture('rss/rss_feed.xml')
        })
      end

      it "syncs using the importer" do
        program = create :external_program, :from_rss, podcast_url: "http://rss.com"
        program.sync
        program.episodes.should_not be_empty
        program.segments.should be_empty
      end
    end
  end

  describe 'slug uniqueness validation' do
    it 'validates that the slug is unique across the program models' do
      kpcc_program = create :kpcc_program, slug: "same"
      external_program = build :external_program, slug: "same"
      external_program.should_not be_valid
      external_program.errors[:slug].first.should match /be unique between/
    end
  end

  describe 'expired episodes' do
    context 'has days_to_expiry timestamp' do
      it "only returns expired episodes" do
        program = create :external_program, :from_rss, air_status: "onair", days_to_expiry: 3

        program.episodes << create(:external_episode, air_date: Time.zone.now)
        program.episodes << (expired_episode = create(:external_episode, air_date: 4.days.ago))

        expired_eps = program.expired_episodes
        expect(expired_eps.count).to eq(1)
        expect(expired_eps[0]).to eq(expired_episode)
      end
    end

    context 'has no days_to_expiry timestamp' do
      it 'returns no episodes' do

        program = create :external_program, :from_rss, air_status: "onair"

        program.episodes << create(:external_episode, air_date: Time.zone.now)
        program.episodes << (expired_episode = create(:external_episode, air_date: 4.days.ago))

        expect(program.expired_episodes).to be_empty
      end
    end
  end

  describe '#has_episode_expiration?' do
    context "#days_to_expiry returns a non-nil and non-zero value" do
      it "returns true" do
        program = build :external_program, days_to_expiry: 3
        expect(program.has_episode_expiration?).to eq true
      end
    end

    context "#days_to_expiry returns nil" do
      it "returns false" do
        program = build :external_program, days_to_expiry: nil
        expect(program.has_episode_expiration?).to eq false
      end
    end
    context "#days_to_expiry returns 0" do
      it "returns false" do
        program = build :external_program, days_to_expiry: 0
        expect(program.has_episode_expiration?).to eq false
      end
    end
  end
end
