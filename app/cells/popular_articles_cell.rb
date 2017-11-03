class PopularArticlesCell < Cell::ViewModel

  cache :show do
    model.try(:cache_key)
  end

  def show
    get_popular_articles
    render if articles.try(:any?)
  end

  def asset_path(article)
    article.try(:asset).try(:full).try(:url) || "/static/images/fallback-img-rect.png"
  end

  def side_bar
    get_popular_articles
    render
  end

  def trio
    render
  end

  def order
    @options[:order] || "1001"
  end

  def articles
    # (@popular_articles_viewed || []).first(4)
    # NewsStory.all.limit(4).map(&:get_article)
    popular_articles_viewed.try(:first, 4)
  end

  def popular_articles_viewed
    if (@popular_articles_viewed || []).any?
      @popular_articles_viewed.try(:first, 4)
    else
      NewsStory.published.order(public_datetime: :desc).all.limit(4).map(&:get_article)
    end
  end

  def popular_articles_discussed
    if (@popular_articles_discussed || []).any?
      @popular_articles_discussed.try(:first, 4)
    else
      NewsStory.published.order(public_datetime: :desc).all.limit(4).map(&:get_article).reverse
    end
  end

  def get_popular_articles
    # We have to rescue here because Marshal doesn't know about
    # Rails' autoloading. This should be a non-issue in production,
    # but just in case (and for development), we should be safe.
    # This is fixed in Rails 4.
    # https://github.com/rails/rails/issues/8167
    prev_klass = nil

    begin
      @popular_articles_viewed = Cache.read("popular/viewed")
      @popular_articles_discussed = Cache.read("popular/commented");
    rescue ArgumentError => e
      klass = e.message.match(/undefined class\/module (.+)\z/)[1]

      # If we already tried to load this class but couldn't,
      # give up.
      if klass == prev_klass
        warn "Error caught: Couldn't deserialize popular articles: #{e}"
        @popular_articles_viewed = []
        @popular_articles_discussed = []
        return
      end

      prev_klass = klass
      klass.constantize # Let Rails load it for us.
      retry
    end
  end
end
