class IngestFeedController < ApplicationController
  layout false
  helper InstantArticlesHelper
  # This is similar to the feeds controller,
  # but contains some helper method overrides
  # to render a more consistently clean body
  # to support Facebook and Apples' specs.
  before_action :retrieve_content

  def facebook_ingest
    response.headers["Content-Type"] = 'text/xml'

    @feed = {
      :title       => "Instant Articles | 89.3 KPCC",
      :description => "Instant Articles from KPCC's reporters, bloggers and shows."
    }

    xml = render_to_string(template: 'feeds/facebook.xml.builder', formats: :xml)

    render text: xml, format: :xml
  end

  def apple_ingest
    response.headers["Content-Type"] = 'text/xml'

    @feed = {
      :title       => "Apple News | 89.3 KPCC",
      :description => "Apple News articles from KPCC's reporters, bloggers and shows.",
      :url         => apple_ingest_feed_url(format: :xml)
    }

    xml = render_to_string(template: 'feeds/apple.xml.builder', formats: :xml)

    render text: xml, format: :xml
  end

  private

  def retrieve_content
    # This is slow, but ElasticSearch wasn't behaving the way I'd 
    # expect when trying to match the bylines of articles to discount
    # non-kpcc articles.
    @content = cache "ingest-feed-controller", skip_digest: true do
      # Cache should be expiring whenever a news story or a blog entry is published or modified(after publish).
      records = NewsStory.published.where(source: "kpcc").order("published_at DESC").limit(15).concat BlogEntry.published.order('published_at DESC').limit(15)
      records.map(&:get_article).sort_by(&:public_datetime).reverse.first(15)
    end
  end
end