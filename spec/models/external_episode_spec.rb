require 'spec_helper'

describe ExternalEpisode do
  describe '#external_episode_segments' do
    it 'orders by position' do
      episode = build :external_episode
      episode.external_episode_segments.to_sql.should match /order by external_episode_segments.position/i
    end
  end

  describe '#external_segments' do
    it 'orders by position' do
      episode = build :external_episode
      episode.segments.to_sql.should match /order by external_episode_segments.position/i
    end
  end

  describe '::for_air_date' do
    it 'matches the dates' do
      t = Time.zone.now.yesterday
      episode = create :external_episode, air_date: t
      ExternalEpisode.for_air_date(t).should eq [episode]
    end
  end

  describe '#to_episode' do
    it 'turns it into an episode' do
      episode = build :external_episode
      episode.to_episode.should be_a Episode
    end
  end

  describe '#to_article' do
    it "turns the episode into an article" do
      episode = build :external_episode
      episode.to_article.should be_a Article
    end
  end
end
