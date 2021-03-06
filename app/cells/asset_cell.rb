class AssetCell < Cell::ViewModel

  property :owner

  def show

    article = @options[:article]

    context = @options[:context] || "default"

    return if asset && @options[:kpcc_only] && !asset.try(:owner).try(:include?, "KPCC")

    if @options[:template]
      tmplt_opts = Array(@options[:template])
    else
      tmplt_opts = [
        "#{context}/#{display}",
        "default/#{display}",
        "#{context}/photo",
        "default/photo"
      ]
    end

    partial = tmplt_opts.find do |template|
      File.exist?("#{Rails.root}/#{self.class.prefixes[0]}/#{template}.erb")
    end

    partial ||= tmplt_opts.last

    render view: partial

  end

  def aspect asset=model
    width = asset.small.width.to_i
    height = asset.small.height.to_i
    if width < height
      "o-figure--portrait"
    else
      # If the asset is an inline asset, give the true aspect ratio - J.A.
      if asset.try(:inline) == true
        "o-figure--full"
      # If it's a lead asset, crop it to classic (4:3) to ensure design consistency - J.A.
      else
        "o-figure--classic"
      end
    end
  end

  def slideshow_assets
    assets.try(:select) {|a| a.inline == false }
  end

  def article
    @options[:article]
  end

  def caption
    (model.caption.blank? ? nil : model.caption) || ""
  end

  def assets
    article.try(:assets) || []
  end

  def asset
    model || @options[:asset] || article.asset || nil
  end

  def src
    model.try(:full).try(:url) || "/static/images/fallback-img-rect.png"
  end

  def public_url
    @options[:article].try(:public_url)
  end

  def display
    if article.try(:asset_display) || @options[:display]
      article.asset_display.to_s
    else
      "photo"
    end
  end

  def title
    model.title || model.caption
  end

  def assethost asset
    if asset
      if asset.try(:eight).try(:asset).try(:native)
        asset.eight.asset.native["class"]
      end
    end
  end

  def videoid asset
    if asset
      if asset.try(:eight).try(:asset).try(:native)
        asset.eight.asset.native["videoid"]
      end
    end
  end

end

