module CategoryHandler
  PER_PAGE = 17

  def handle_category
    page      = params[:page].to_i
    per_page  = PER_PAGE
    @content = @category.content(
      :page       => page,
      :per_page   => per_page
    )
    if @category.featured_articles.any?
      @featured_articles = @category.featured_articles
      @lead_article = @featured_articles.first
      @featured_image ||= @lead_article.asset
      @resources = @featured_articles[1..4]
      @featured_interactive = @featured_articles[5]

      if @lead_article.original_object.issues.any?
        @issues = @lead_article.original_object.issues
        @primary_issue = @issues.first
        @top_two_issue_articles = @primary_issue.articles.first(2)
      end

    end

    @category_articles = @content.map { |a| a.to_article }
    @latest_articles = @category_articles[1..2]
    @three_recent_articles = @category_articles[3..5]
    @top_half_recent_articles = @category_articles[6..7]
    @bottom_half_recent_articles = @category_articles[8..9]
    @more_articles = @category_articles[10..-1]

    if @category.issues.any?
      @category_issues = @category.issues
      @special_issue = @category_issues.first
      @other_issues = @category_issues[1..2]
      @top_two_special_issue_articles ||= @special_issue.articles.first(2)
    end

    if @category.events.published.upcoming.any?
      @events = @category.events.published.upcoming
      @latest_event = @events.first.to_article
      @upcoming_events = @events[1..3].map { |a| a.to_article }
    end

    if @category.quotes.published.any?
      @quote = @category.quotes.published.first
      @quote_article = @quote.article.to_article
    end

    if @category.bios.any?
      @bios = @category.bios
      @twitter_feeds = @bios.map(&:twitter_handle)
    end
    respond_with @content, template: "category/show", layout: "vertical"
  end
end
