xml.rss({
  "version" => "2.0",
  "xmlns:content" => "http://purl.org/rss/1.0/modules/content/",
  "xmlns:IA" => "http://rss2.io/ia/"
}) do
  xml.channel do
    xml.title       "89.3 | KPCC"
    xml.link        "http://#{Rails.application.default_url_options[:host]}", rel: "canonical"
    xml.description "Southern California Public Radio"

    @content.each do |content|
      xml.item do
        xml.title content.headline
        xml.description content.teaser
        xml.tag! 'content:encoded' do
          xml.cdata! render(
            partial: 'feeds/shared/instant_article', 
            formats: ['html'],
            layout: false, 
            locals: {content: content}
          ).gsub("\n", "")
        end
        xml.guid  content.public_url
        xml.link  content.public_url
        xml.author content.byline
        xml.pubDate content.published_at.iso8601
      end
    end
  end
end

# @embeditor.close