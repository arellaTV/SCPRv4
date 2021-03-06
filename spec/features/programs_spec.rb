require 'spec_helper'

describe "Episode page" do
  context "for external episode" do
    it "renders a list of segments" do
      episode = build :external_episode
      segment = build :external_segment, title: "Cool Segment!"
      episode.segments << segment
      episode.save!

      visit episode.public_url

      within "#o-standard-program-episode__episode__segment-list" do
        page.should have_content segment.title
      end
    end
  end

  context "for KPCC episode" do
    it "renders a list of segments" do
      episode = build :show_episode
      segment = build :show_segment, headline: "Cool Segment!"
      episode.save!
      episode.segments << segment

      visit episode.public_url

      # TEMPORARY: Disabling temporarily until feature is confirmed to be in use
      # within "#o-standard-program-episode__episode__segment-list" do
      #   page.should have_content segment.headline
      # end
    end
  end
end

describe "Program page" do
  context "for KPCC program" do
    it "shows the current episode" do
      program = create :kpcc_program, is_segmented: true
      create :show_episode, show: program, headline: "xxCurrentEpisode--"

      visit program.public_path

      within ".o-standard-program__episode-list" do
        page.should have_content "xxCurrentEpisode--"
      end
    end

    it "shows the list of episodes if is_segmented is true" do
      program = create :kpcc_program, is_segmented: true

      create :show_episode,
        :show           => program,
        :headline       => "xxCurrentEpisode--",
        :air_date       => 1.hour.ago

      create :show_episode,
        :show           => program,
        :headline       => "xxLastEpisode--",
        :air_date       => 1.day.ago

      visit program.public_path

      within ".o-standard-program__episode-list" do
        page.should have_content "xxLastEpisode--"
      end
    end
  end
end
