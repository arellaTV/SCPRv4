class ArticlePresenter < ApplicationPresenter
  presents :article

  def asset_display
    asset_display = article.original_object.asset_display
    if asset_display == :slideshow
      render 'shared/new/assets/slideshow', article: article
    elsif asset_display == :video
      render 'shared/new/assets/video', article: article
    elsif asset_display == :hidden || asset_display == :photo_deemphasized || article.original_object.assets.blank?
      render 'shared/new/assets/hidden', article: article
    else
      render 'shared/new/assets/photo', article: article
    end
  end

  def inline_asset
    if (article.original_object.asset_display == :photo_deemphasized) || (article.original_object.asset_display.blank? && !below_standard_ratio(width: article.asset.full.width, height: article.asset.full.height)) || (article.original_object.asset_display == :photo_emphasized && !below_standard_ratio(width: article.asset.full.width, height: article.asset.full.height))
      render 'shared/new/inline_asset', article: article
    end
  end

  def related_links
    if article.original_object.related_links.present? || article.original_object.related_content.present?
      s = "".html_safe
      h.content_tag :aside, class: "related" do
        l = h.content_tag :header do
          h.content_tag :h1 do
            "Related Links"
          end
        end
        l += h.content_tag :nav do
          h.content_tag :ul do
            inbound_links + outbound_links
          end
        end
      end
    end
  end

  private

  def outbound_links
    s = "".html_safe
    if article.original_object.related_links.present?
      article.original_object.related_links.each do |related_link|
        domain = URI.parse(related_link.url).host.sub(/^www\./, '')
        kpcc_link = domain.split(".").include?("scpr")
        class_options = {}
        class_options[:class] = "track-event"
        class_options[:class] << " outbound" unless kpcc_link
        class_options[:class] << " query" if related_link.link_type == "query"
        s += h.content_tag :li, class: class_options[:class] do
          r = h.link_to related_link.url do
            l = h.content_tag :mark do
              related_link.title
            end
            l += h.content_tag :span do
              if related_link.link_type == "query"
                "Contribute Your Voice"
              elsif kpcc_link
                "Article"
              else
                "Source: #{domain}"
              end 
            end
          end
          r += h.content_tag :span do
            if related_link.link_type == "query"
             h.link_to "/network/", class: "pij" do
              "Learn more about the Public Insight Network"
              end
            end
          end
        end
      end
    end
    s
  end

  def inbound_links
    s = "".html_safe
    if article.original_object.related_content.present?
      article.original_object.related_content.each do |related_article|
        class_options = {}
        class_options[:class] = "track-event"
        class_options[:class] << " #{related_article.feature.key.to_s}" if related_article.feature.try(:key).present?
        class_options[:data] = {"ga-category" => "Article", "ga-action" => "Clickthrough", "ga-label" => "Related" }
        s += h.content_tag :li, class_options do
          h.link_to related_article.public_path do
            l = h.content_tag :mark do
              related_article.short_title
            end
            l += h.content_tag :span do
              related_article.feature.try(:name) || "Article"
            end
          end
        end
      end
    end
    s
  end

end
