class UpcomingEventsCell < Cell::ViewModel
  def show
    render if events.any?
  end

  def category_name
    if @options[:category_name] == 'Politics'
      'Political'
    else
      @options[:category_name]
    end
  end

  def events
    if @options[:upcoming_events].any?
      @options[:upcoming_events]
    elsif @options[:past_events].any?
      @options[:past_events]
    else
      []
    end
  end

  def asset_path(resource)
    asset_display = resource.try(:asset_display)
    assets = resource.try(:assets)
    if asset_display == :hidden || asset_display == "hidden" || assets.try(:empty?)
      nil
    else
      resource.try(:asset).try(:small).try(:url) || "/static/images/fallback-img-rect.png"
    end
  end

  def time_adjective
    if @options[:upcoming_events].any?
      'Upcoming'
    elsif @options[:past_events].any?
      'Past'
    else
      []
    end
  end

end
