##
# Flatpages
#
FactoryGirl.define do
  factory :flatpage do
    sequence(:path)        { |n| "about-#{n}/wat" }
    title                 "About"
    content               "This is the about content"
    description           "This is the description"
    is_public             1
    template              "inherit"
    extra_head "" # can't be null
    extra_tail "" # can't be null
  end
end
