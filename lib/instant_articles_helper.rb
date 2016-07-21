module InstantArticlesHelper

  def render_asset(content, options={})
    # For now, we're only going to render any assets that we own.
    asset = options[:asset] || nil
    return if asset && !asset.owner.try(:include?, "KPCC")
    if options[:asset_display]
      asset_display = options[:asset_display]
    else 
      asset_display = 'default'
    end
    render partial: "feeds/shared/instant_articles/#{asset_display}", locals: {content: content, asset: asset}
  end

  def render_lead_asset content
    path = Rails.root.join('app', 'views', 'feeds', 'shared', 'instant_articles')
    if Dir.glob("#{path}/*").join("").include?(content.feature.try(:asset_display) || 'NO_ASSET')
      asset_display = content.feature.try(:asset_display)
    else 
      asset_display = 'default'
    end
    render_asset content, asset_display: asset_display
  end

  def render_body content
    relaxed_sanitize strip_embeds insert_inline_assets content
  end

  def strip_embeds body
    doc = Nokogiri::HTML(body.force_encoding('ASCII-8BIT'))
    doc.css(".embed-placeholder, .embed-wrapper").each{|placeholder|
      placeholder.replace Nokogiri::HTML::DocumentFragment.parse("")
    }
    doc.css('body').children.to_s.html_safe
  end

  def insert_inline_assets content, options={}
    cssPath = "img.inline-asset[data-asset-id]"
    context = options[:context] || "news"
    display = options[:display] || "inline"
    doc = Nokogiri::HTML(content.body)
    doc.css(cssPath).each do |placeholder|
      asset_id = placeholder.attribute('data-asset-id').value
      asset = content.original_object.assets.find_by(asset_id:asset_id)
      ## If kpcc_only is true, only render if the owner of the asset is KPCC
      if asset
        rendered_asset = render_asset content, context: context, display: display, asset:asset
        placeholder.replace Nokogiri::HTML::DocumentFragment.parse(rendered_asset)
      else
        placeholder.replace Nokogiri::HTML::DocumentFragment.parse("")
      end
    end
    doc.css("body").children.to_s.html_safe
  end
end