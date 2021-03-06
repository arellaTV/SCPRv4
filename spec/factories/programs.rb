##
# Programs
#
FactoryGirl.define do
  factory :kpcc_program, aliases: [:show] do
    sequence(:title) { |n| "Show #{n}" }
    slug { title.parameterize }
    air_status "onair"

    audio_dir "airtalk" # lazy
  end

  factory :program_article do
    kpcc_program
    article { |f| f.association(:news_story) }
    position 0

    trait :episode do
      article { |f| f.association(:show_episode) }
      position 0
    end
  end

  factory :program_reporter do
    kpcc_program
    bio
  end
end
