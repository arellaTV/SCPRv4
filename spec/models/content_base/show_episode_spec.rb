require "spec_helper"

describe ShowEpisode do
  describe '#segments' do
    it 'orders by position' do
      episode = build :show_episode
      episode.segments.to_sql.should match /order by shows_rundown.position/i
    end
  end

  describe "callbacks" do
    describe "generate_headline" do
      let(:program) { build :kpcc_program, title: "Cool Show" }

      it "generates headline if headline is blank" do
        episode = build :show_episode, show: program, air_date: Time.zone.local(2012, 1, 1), headline: ""
        episode.save!
        episode.reload.headline.should eq "Cool Show for January 1, 2012"
      end

      it "doesn't generate headline if headline was given" do
        episode = build :show_episode, headline: "Cool Episode, Bro!"
        episode.save!
        episode.reload.headline.should eq "Cool Episode, Bro!"
      end
    end

    describe "create_podcast_episode" do
      before :each do
        $megaphone = MegaphoneClient.new({
          token: "INITIAL_EMPTY_RESPONSE_STUB"
        })
      end

      it "only executes a POST request if the associated podcast has an external podcast id" do
        podcast = build :podcast, title: "The Cooler Podcast"
        program = build :kpcc_program, title: "The Cooler Show", podcast: podcast
        episode = create :show_episode, show: program
        expect(WebMock).to_not have_requested(:post, %r|cms\.megaphone\.fm\/api\/|)

        podcast = build :podcast, title: "The Coolest Podcast", external_podcast_id: "EXTERNAL_PODCAST_ID_STUB"
        program = build :kpcc_program, title: "The Coolest Show", podcast: podcast
        episode = create :show_episode, show: program
        expect(WebMock).to have_requested(:post, %r|cms\.megaphone\.fm\/api\/|).once
      end

      it "performs a PUT request if an mp3 is uploaded" do
        podcast = build :podcast, title: "The Coolest Podcast", external_podcast_id: "EXTERNAL_PODCAST_ID_STUB"
        program = build :kpcc_program, title: "The Coolest Show", podcast: podcast
        episode = create :show_episode, show: program
        audio = build :audio, :uploaded, mp3: load_audio_fixture("point1sec.mp3"), content: episode
        audio.save!

        expected_json_from_post = {
          author: episode.show.title,
          draft: false,
          externalId: "#{episode.obj_key}__#{Rails.env}",
          pubdateTimezone: Time.zone.name,
          pubdate: episode.air_date,
          summary: episode.teaser,
          title: episode.headline
        }.to_json

        expected_json_from_put = {
          backgroundAudioFileUrl: audio.url
        }.to_json

        expect(WebMock)
          .to have_requested(:post, %r|cms\.megaphone\.fm\/api\/|)
          .with(body: expected_json_from_post)
      end

      it "defaults with a pubdate in the future if none is given" do
        podcast = build :podcast, title: "The Cooler Podcast", external_podcast_id: "EXTERNAL_PODCAST_ID_STUB"
        program = build :kpcc_program, title: "The Cooler Show", podcast: podcast
        episode = create :show_episode, show: program

        expect(WebMock).to have_requested(:post, %r|cms\.megaphone\.fm\/api\/|)
          .with { |req| expect(req.body).to match(/pubdate/) }
      end
    end

    describe "update_podcast_episode" do
      before :each do
        $megaphone = MegaphoneClient.new({
          token: "INITIAL_EMPTY_RESPONSE_STUB"
        })
      end

      it "creates the episode record in the podcast cms if it doesn't already exist" do
        episode = create :show_episode
        podcast = build :podcast, title: "The Cooler Podcast", external_podcast_id: "EXTERNAL_PODCAST_ID_STUB"
        program = build :kpcc_program, title: "The Cooler Show", podcast: podcast
        episode.show = program
        episode.save!

        expect(WebMock).not_to have_requested(:put, %r|cms\.megaphone\.fm\/api\/|)
        expect(WebMock).to have_requested(:post, %r|cms\.megaphone\.fm\/api\/|)
      end
    end
  end

  #------------------

  describe "validations" do
    it "validates air date on publish" do
      ShowEpisode.any_instance.stub(:published?) { true }
      should validate_presence_of(:air_date)
    end
  end

  #------------------

  describe "scopes" do
    describe "#published" do
      it "orders published content by air_date descending" do
        episodes = create_list :show_episode, 3, :published
        ShowEpisode.published.first.should eq episodes.last
        ShowEpisode.published.last.should eq episodes.first
      end
    end
  end

  #------------------

  describe '#publish' do
    it "published the episode" do
      episode = create :show_episode, :unpublished
      episode.published?.should eq false

      episode.publish
      episode.published?.should eq true
    end
  end


  describe '#rundowns_json' do
    it "uses simple_json for the join model" do
      episode = create :show_episode
      segment = create :show_segment
      rundown = episode.rundowns.build(content: segment, position: 0)
      rundown.save!

      episode.rundowns_json.should eq [rundown.simple_json].to_json
      episode.segments.should eq [segment]
    end
  end

  #------------------

  describe 'attached rundowns' do
    it "saves them along with the episode" do
      episode = build :show_episode
      seg1 = create :show_segment
      seg2 = create :show_segment

      episode.segments << seg1
      episode.segments << seg2

      episode.save!

      episode.rundowns.count.should eq 2
      episode.rundowns.first.position.should eq 1
      episode.rundowns.last.position.should eq 2
    end
  end

  describe '#rundowns_json=' do
    let(:episode)  { create :show_episode }
    let(:segment1) { create :show_segment }
    let(:segment2) { create :show_segment }


    it "adds them ordered by position" do
      episode.rundowns_json = "[{ \"id\": \"#{segment2.obj_key}\", \"position\": 1 }, {\"id\": \"#{segment1.obj_key}\", \"position\": 0 }]"
      episode.segments.should eq [segment1, segment2]
    end

    it "parses the json and sets the content" do
      episode.segments.should be_empty
      episode.rundowns_json = "[{\"id\": \"#{segment1.obj_key}\", \"position\": 0 }, { \"id\": \"#{segment2.obj_key}\", \"position\": 1 }]"
      episode.segments.should eq [segment1, segment2]
    end

    it 'does not do anything if json is an empty string' do
      episode.segments.should be_empty
      episode.rundowns_json = "[{\"id\": \"#{segment1.obj_key}\", \"position\": 0 }, { \"id\": \"#{segment2.obj_key}\", \"position\": 1 }]"
      episode.segments.should_not be_empty

      episode.rundowns_json = ""
      episode.segments.should_not be_empty

      episode.rundowns_json = "[]"
      episode.segments.should be_empty
    end

    context "when no content has changed" do
      it "doesn't set the rundowns" do
        original_json = "[{ \"id\": \"#{segment1.obj_key}\", \"position\": 1 }]"
        record = create :show_episode
        record.rundowns_json = original_json

        record.should_not_receive :rundowns=
        record.rundowns_json = original_json
      end
    end
  end

  describe '#to_episode' do
    it 'turns it into an episode' do
      episode = build :show_episode
      episode.to_episode.should be_a Episode
    end
  end

  describe '#to_article' do
    it 'turns it into an article' do
      episode = build :show_episode
      episode.to_article.should be_a Article
    end
  end

  describe 'body generate' do
    it 'generates a body if it is blank on publish' do
      episode = create :show_episode, :published, body: "", teaser: "hello"
      episode.body.should eq "hello"
    end
  end
end