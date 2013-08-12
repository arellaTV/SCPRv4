require 'spec_helper'

describe Job::SendBreakingNewsMobileNotification do
  before :each do
    FakeWeb.register_uri(:get, %r|api\.parse\.com|, 
      :content_type   => "application/json",
      :body           => { result: true }.to_json
    )
  end

  describe '::perform' do
    it 'sends the mobile notification', focus: true do
      alert = create :breaking_news_alert, :mobile, :published
      Job::SendBreakingNewsMobileNotification.perform(alert.id)

      alert.reload.mobile_notification_sent?.should eq true
    end
  end
end
