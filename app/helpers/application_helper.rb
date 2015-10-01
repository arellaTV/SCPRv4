module ApplicationHelper
  include Twitter::Autolink

  HEADSHOTS = [
    "personalities/stoltze.png",
    "personalities/peterson.png",
    "personalities/guzman-lopez.png",
    "personalities/julian.png",
    "personalities/watt.png",
    "personalities/oneil.png"
  ]

  def add_ga_tracking_to(url)
    analytics_params = "?utm_source=kpcc&utm_medium=email&utm_campaign=short-list"
    url =~ /scpr\.org/ ? url + analytics_params : url
  end

  def present(object, klass=nil)
    klass ||= "#{object.class}Presenter".constantize
    presenter = klass.new(object, self)
    yield presenter if block_given?
    presenter
  end


  # A hash in which to store meta data for the template META tags.
  # This is what should be used in the <head> tag to build the META tags.
  def meta_information
    @meta_hash ||= {}
  end

  # Add meta tags to the meta_information hash.
  def meta_tags(hash)
    meta_information.merge!(hash)
  end


  # Safely render a partial, without having to worry about whether it exists
  # or not. This should only be used when rendering partials based on user
  # input, and only when it is expected that sometimes there may not be
  # a partial to render. This is useful for conditionally rendering chunks
  # of a page based on a nesting hierarchy such as category or blog.
  #
  # This has the same signature as `render` *in the variable args form*.
  # It won't work with the hash form.
  #
  # Example
  #
  #   <%= safe_render "category/#{@category.slug.underscore}" %>
  def safe_render(*args)
    partial = args.first

    if lookup_context.exists?(partial, [], true)
      render *args
    end
  end


  #---------------------------
  # render_content takes a ContentBase object and a context, and renders
  # using the most specific version of that context it can find.
  #
  # For instance, if your content is a "news/story" and your context is
  # "lead", render_content will try:
  #
  # * shared/content/news/story/lead
  # * shared/content/news/lead
  # * shared/content/default/lead
  #
  def render_content(content, context, options={})
    return '' if content.blank?
    html = ''

    Array(content).compact.each do |article|
      if article.is_a?(Article)
        directory   = article.obj_class
      else
        directory   = article.class.name.underscore
      end

      tmplt_opts  = ["#{directory}/#{context}", "default/#{context}"]

      partial = tmplt_opts.find do |template|
        self.lookup_context.exists?(template, ["shared/content"], true)
      end

      # -- do we have a cache? -- #

      tmplt_digest = ActionView::Digestor.digest(
        name: "shared/content/#{partial}.#{options[:format] || self.lookup_context.rendered_format}",
        finder: lookup_context,
        partial: true,
      )

      html << with_output_buffer do
        cache(["content",context,article,tmplt_digest], skip_digest:true) do
          self.output_buffer << render(
            "shared/content/#{partial}",
            :article => article.to_article,
            :options => options
          ).html_safe
        end
      end
    end

    html.html_safe
  end


  # render_asset takes a ContentBase object and a context, and renders using
  # an optional asset_display attribute on the object.
  #
  # For example, given a context of "story", render_asset will check for an
  # asset_display attribute on the object.  If found (let's assume with a
  # value of "photo"), it will try to render:
  #
  # * shared/assets/story/photo
  # * shared/assets/default/photo
  # * shared/assets/story/default
  # * shared/assets/default/default
  def render_asset(content, options={})
    article = content.to_article
    context = options[:context] || "default"

    asset = options[:asset] || nil

    if !asset && article.assets.empty?
      html = if options[:fallback]
        render("shared/assets/#{context}/fallback", article: article)
      else
        ''
      end

      return html
    end

    if options[:template]
      tmplt_opts = Array(options[:template])
    else
      display = options[:display]
      display ||= if content.respond_to?(:asset_display)
        content.asset_display
      else
        "photo"
      end

      tmplt_opts = [
        "#{context}/#{display}",
        "default/#{display}",
        "#{context}/photo",
        "default/photo"
      ]
    end

    partial = tmplt_opts.find do |template|
      self.lookup_context.exists?(template, ["shared/assets"], true)
    end

    partial ||= tmplt_opts.last

    render "shared/assets/#{partial}",
      :asset      => asset || article.asset,
      :assets     => article.assets,
      :article    => article
  end

  #----------

  def render_with_inline_assets content, options={}
    cssPath = "img.inline-asset[data-asset-id]"
    doc = Nokogiri::HTML(content.body)
    doc.css(cssPath).each do |placeholder|
      asset_id = placeholder.attribute('data-asset-id').value

      # we have to fall back to original_object here to get the full list of
      # assets. in any case where we're rendering a body, we'll already have
      # the original object loaded, so that's ok
      asset = content.original_object.assets.find_by(asset_id:asset_id)

      if asset
        rendered_asset = render_asset content, context:"news", display:"inline", asset:asset
        placeholder.replace Nokogiri::HTML::DocumentFragment.parse(rendered_asset)
      else
        # FIXME: I'm sure there's a cleaner "delete"
        placeholder.replace Nokogiri::HTML::DocumentFragment.parse("")
      end
    end

    doc.to_s.html_safe
  end

  #----------

  def random_headshot
    image_tag HEADSHOTS.sample
  end

  #----------
  # Render the tag necessary for the Smart Date JS to pick it up.
  # Arguments:
  # * datetime - An object that response to strftime
  # * options  -  * tag - The tag to use (default: 'time')
  #               * class - Any class to prepend to the defaults
  #               * Anything else gets merged into the tag as attributes.
  def smart_date_js(datetime, options={})
    return '' if !datetime.respond_to?(:strftime)

    options[:tag] ||= 'time'

    content_tag options.delete(:tag), nil, {
      "class" => "#{options.delete(:class)} smart smarttime",
      "data-unixtime" => datetime.to_i
    }.merge(options)
  end

  def should_inline_asset_for(article)
    asset = article.asset

    asset && (article.asset_display == :photo_deemphasized) || (article.asset_display.blank? && !below_standard_ratio(width: asset.full.width, height: asset.full.height)) || (article.asset_display == :photo_emphasized && !below_standard_ratio(width: asset.full.width, height: asset.full.height))
  end

  def below_standard_ratio(options={})
    ratio = (3.0/4.0)
    return options[:height].to_f/options[:width].to_f <= ratio && options[:width] > 700
  end

  def below_vertical_ratio(options={})
    ratio = 1.35
    return options[:width].to_f/options[:height].to_f <= ratio
  end
  #----------
  # Render a byline for the passed-in content
  # If links is set to false, and the content has
  # bylines, this will yield the same as +content.byline+
  #
  # If the content doesn't have bylines, just return
  # "KPCC" for opengraph stuff.
  def render_byline(content, links=true)
    return "KPCC" if !content.respond_to?(:joined_bylines)

    elements = content.joined_bylines do |bylines|
      link_bylines(bylines, links)
    end

    ContentByline.digest(elements).html_safe
  end

  #---------------------------

  def render_contributing_byline(content,links=true)
    elements = content.joined_bylines do |bylines|
      link_bylines(bylines, links)
    end

    if elements[:contributing].present?
      "With contributions by #{elements[:contributing]}".html_safe
    else
      ""
    end
  end

  #---------------------------
  # Return an array of the passed-in bylines
  # either tranformed into links, or just
  # the name.
  #
  # This is mostly for +render_byline+ and
  # +render_contributing_byline+ to share.
  def link_bylines(bylines, links)
    bylines.map do |byline|
      if !!links && byline.user.try(:is_public)
        link_to byline.display_name, byline.user.public_path
      else
        byline.display_name
      end
    end
  end

  #---------------------------
  # Convert a given number of seconds into a human-readable duration.
  def format_duration(secs)
    if !secs
      return ''
    end

    [[60, :sec], [60, :min], [24, :hr], [1000, :days]].map{ |count, name|
      if secs > 0
        secs, n = secs.divmod(count)
        "#{n.to_i} #{name}"
      end
    }.compact.reverse.join(' ')
  end

  #--------------------------

  def format_clip_duration(secs)
    if !secs
      return ''
    end
    time_format = secs >= 3600 ? "%-H:%M:%S" : "%-M:%S"
    Time.zone.at(secs).utc.strftime(time_format)
  end

  #----------

  def latest_news
    ContentBase.search({
      :classes  => [NewsStory, BlogEntry, ShowSegment, ContentShell],
      :limit    => 2,
      :with     => { "category.slug" => true },
    })
  end

  def latest_blogs(limit=3)
    BlogEntry.published.includes(:blog).limit(limit)
  end

  def upcoming_events_forum
    Event.published.includes(:assets).upcoming.forum.limit(2)
  end

  def upcoming_events_sponsored
    Event.published.includes(:assets).upcoming.sponsored.limit(3)
  end

  #----------

  def link_to_audio(title, article, options={}) # This needs to be more useful
    article = article.to_article
    return nil if article.audio.empty?

    options[:class] = "audio-toggler #{options[:class]}"
    options[:title] ||= article.short_title
    options["data-duration"] = article.audio.first.duration

    content_tag :div, link_to(title, article.audio.first.url, options),
      :class => "story-audio inline"
  end

  #---------------------------

  def twitter_profile_url(handle)
    "https://twitter.com/#{handle.parameterize}"
  end

  #---------------------------

  def modal(cssClass, options={}, &block)
    content_for(:modal_content, capture(&block))
    render('shared/modal_shell', cssClass: cssClass, options: options)
  end

  #---------------------------

  def relaxed_sanitize(html)
    Sanitize.clean(html.to_s.html_safe, Sanitize::Config::RELAXED)
  end

  #---------------------------

  def split_collection(array, num)
    last_num  = array.size - num
    first     = array.first(num)
    last      = array.last(last_num < 0 ? 0 : last_num)
    return [first, last]
  end

  #----------

  def pij_source(content, options={})
    message = options[:message] || "This story was informed by KPCC listeners."

    if content.is_from_pij?
      render 'shared/pij_notice', message: message
    end
  end

  #----------
  # Render a timestamp inside of a time tag.
  #
  # time_tag uses i18n's `localize` method, which raises
  # if the date passed in doesn't respond to strftime, so we
  # need to check that this is the case before rendering the
  # time tag. Otherwise previewing unpublished content breaks.
  def timestamp(datetime)
    if datetime.respond_to?(:strftime)
      time_tag(datetime,
        format_date(datetime,
          :format   => :full_date,
          :time     => true
        ),
        :pubdate => true
      )
    end
  end

  def format_date(time, format=:long, blank_message="&nbsp;")
      time.blank? ? blank_message : time.to_s(format)
  end


  #----------

  def comment_widget_for(object, options={})
    if has_comments?(object)
      content_widget (options[:partial] || 'comment_count'), object, options
    end
  end

  def comments_for(object, options={})
    if has_comments?(object)
      content_widget('comments', object, { header: true }.merge(options))
    end
  end

  def comment_count_for(object, options={})
    if has_comments?(object)
      options[:class] = "comment_link social_disq #{options[:class]}"
      options["data-objkey"] = object.disqus_identifier

      link_to("Add your comments",
        object.public_path(anchor: "comments", ), options)
    end
  end

  def has_comments?(object)
    object.respond_to?(:disqus_identifier)
  end


  #----------

  def content_widget(partial, object, options={})
    partial = "shared/cwidgets/#{partial}" if partial.chars.first != "/"
    article = (options[:to_article] || options[:to_article].nil?) ? object.to_article : object
    render(partial, {
      :article  => article,
      :options  => options,
    })
  end

  #---------------
  # These two methods are taken from EscapeUtils
  def html_escape(string)
    EscapeUtils.escape_html(string.to_s).html_safe
  end
  alias_method :h, :html_escape

  def url_encode(s)
    EscapeUtils.escape_url(s.to_s).html_safe
  end
  alias_method :u, :url_encode


  # Safely add parameters to any URL
  #
  # Examples
  #
  #   url_with_params("http://google.com", something: "cool")
  #   # => "http://google.com?something=cool"
  #
  #   url_with_params("http://google.com?cool=thing", another: "params")
  #   # => "http://google.com?cool=thing&another=params"
  #
  # Falsey values will not be added to the parameters. If you want
  # an empty parameter, pass an empty string.
  #
  #   url_with_params("http://google.com", something: nil)
  #   # => "http://google.com"
  #
  #   url_with_params("http://google.com", something: "")
  #   # => "http://google.com?something="
  #
  # Returns String
  def url_with_params(url, params={})
    begin
      uri = URI.parse(url)
    rescue URI::InvalidURIError => e
      # We want to know about these invalid URIs so we can fix them,
      # but it shouldn't prevent the entire page from loading if there's
      # one bad URL.
      NewRelic.log_error(e)
      return url
    end

    query = URI.decode_www_form(uri.query.to_s)

    params.each { |k, v| query << [k.to_s, v.to_s] if v }

    uri.query = URI.encode_www_form(query)
    uri.to_s.chomp("?")
  end
end
