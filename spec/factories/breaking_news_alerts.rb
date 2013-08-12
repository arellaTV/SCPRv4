##
# Breaking News Alerts
#
FactoryGirl.define do
  factory :breaking_news_alert do
    headline      "Breaking news!"
    teaser        "This is breaking news"
    alert_time    { Time.now }
    alert_type    "break"
    alert_url    "http://scpr.org/"
    visible       true

    send_email    false
    email_sent    false

    send_mobile_notification false
    mobile_notification_sent false

    trait :email do
      send_email true
    end

    trait :mobile do
      send_mobile_notification true
    end
  end
end
