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
      rundown = episode.rundowns.build(segment: segment, position: 0)
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

  describe '#for_show_page' do
    program = nil
    before :each do
      program = create :kpcc_program
      5.times { program.episodes << create(:show_episode) }
    end
    it 'limits the number of episodes' do
      eps = program.episodes.for_show_page 1, 2
      expect(eps.count).to be 2
    end 
    it 'returns all episodes if no pagination parameters are provided' do
      eps = program.episodes.for_show_page
      expect(eps.count == program.episodes.count).to eq(true)
    end 
    it 'removes a current episode if provided' do
      current_episode = program.episodes.first
      eps = program.episodes.for_show_page 1, 10, current_episode
      expect(eps.include?(current_episode)).to eq(false)
    end 
  end

end
