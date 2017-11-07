# As in an actual Article and not one of our ContentBase models.
# NEVER not an Article.  NOT original_object -- DON'T DO IT.
# NO, JUST NO.  If it's not there, add it to the Article class.

class ArticleCell < Cell::ViewModel
  include Cell::Caching::Notifications
  include ActionView::Helpers::DateHelper
  property :title
  property :body
  property :assets
  property :asset
  property :category

  cache :show do
    model.try(:cache_key)
  end

  def show
    render
  end

  def audio_nav
    render
  end

  def biographies links=true
    elements = model.try(:joined_bylines) do |bylines|
      bylines.map do |byline|
        if links && byline.user.try(:is_public)
          link_to byline.display_name, byline.user.public_path
        else
          byline.display_name
        end
      end
    end
    elements || {}
  end

  def contributing_byline
    if biographies[:contributing] && biographies[:contributing].length > 0
      "With contributions from #{biographies[:contributing]}".html_safe
    end
  end

  def pij_source options={}
    message = options[:message] || "This story was informed by KPCC listeners."

    if model.try(:is_from_pij?)
      render locals: { message: message }
    end
  end

  def asset_path(resource)
    resource.try(:asset).try(:small).try(:url) || "/static/images/fallback-img-rect.png"
  end

  def hero_asset(figure_class)
    if model.try(:asset_display) != :hidden || !model.try(:assets).try(:empty?)
      if model.try(:asset_display) == :slideshow
        AssetCell.new(asset, article: model, class: figure_class, template: "default/#{model.try(:asset_display)}.html").call(:show)
      else
        AssetCell.new(asset, article: model, class: figure_class).call(:show)
      end
    end
  end

  def render_body options={}
    cssPath = "img.inline-asset[data-asset-id]"
    context = options[:context] || "news"
    display = options[:display] || "inline"
    doc = Nokogiri::HTML(body)
    doc.css(cssPath).each do |placeholder|
      asset_id = placeholder.attribute('data-asset-id').value
      asset_id = asset_id ? asset_id.to_i : nil
      next if asset_id.nil?

      # we have to fall back to original_object here to get the full list of
      # assets. in any case where we're rendering a body, we'll already have
      # the original object loaded, so that's ok
      asset = model.try(:inline_assets).select{|a| a.asset_id == asset_id}[0]

      ## If kpcc_only is true, only render if the owner of the asset is KPCC
      if asset && (!options[:kpcc_only] || asset.owner.try(:include?, "KPCC"))
        if (asset.small.width.to_i < asset.small.height.to_i)
          if placeholder.attribute('data-align').try(:value).try(:match, /left/i)
            positioning = "o-article__body--float-left"
          else
            positioning = "o-article__body--float-right"
          end
        end
        rendered_asset = AssetCell.new(asset, context: context, display: display, article: model, class: positioning).call(:show)
        placeholder.replace Nokogiri::HTML::DocumentFragment.parse(rendered_asset)
      else
        # FIXME: I'm sure there's a cleaner "delete"
        placeholder.replace Nokogiri::HTML::DocumentFragment.parse("")
      end
    end
    order_body doc
    doc.css("body").children.to_s.html_safe
  end

  def order_body doc
    doc.css("body > *").each_with_index do |element, i|
      element['style'] ||= ""
      unless element['style'].match(/order:\s(.*);/)
        element['style'] += "order:#{i};"
      end
    end
  end

  # def byline links=true
  #   return "KPCC" if !model.respond_to?(:attributions)
  #   # The order of priority with ContentByline roles
  #   # is in ascending order, so we can just do a
  #   # simple sort.
  #   bylines   = model.attributions.sort_by{|b| b.role}
  #   if bylines.empty?
  #     bylines << Hashie::Mash.new({name: "KPCC", role: -1})
  #   end
  #   primaries = bylines.select{|b| (b.role || 0) > -1}.map(&:name).join(" and ")
  #   extras    = bylines.select{|b| (b.role || 0) < 0 }.map(&:name).join(" | ")

  #   source    = NewsStory::SOURCES.select{|x| x[1] == model.try(:source)}.flatten[0]

  #   [primaries, extras, source].reject{|b| b.blank?}.join(" | ")
  # rescue NoMethodError
  #   "KPCC"
  # end

  def timestamp
    datetime = model.public_datetime.try(:strftime, "%B %-d, %Y")
    if datetime
      "<time datetime=\"#{model.public_datetime.try(:iso8601)}\">" +
        datetime +
      "</time>"
    end
  end

  def format_date time, format=:long, blank_message="&nbsp;"
    time.blank? ? blank_message : time.to_s(format)
  end

end
