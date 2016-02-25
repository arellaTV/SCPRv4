class CategoryPreview
  DEFAULTS = {
    :limit => 5
  }

  attr_reader \
    :category,
    :articles,
    :top_article,
    :bottom_articles,
    :sorted_articles,
    :candidates,
    :featured_object


  def initialize(category, options={})
    limit = options[:limit] || DEFAULTS[:limit]

    @category = category
    @excludes  = Array(options[:exclude])

    @candidates = find_candidates

    if @featured_object = find_featured_object
      @excludes.push(@featured_object)
    end

    @articles = ContentBase.search({
      :classes    => [NewsStory, BlogEntry, ContentShell, ShowSegment],
      :limit      => limit,
      :with       => { "category.id" => @category.id },
      :without    => { obj_key: @excludes.map(&:obj_key) }
    })

    @top_article      = find_top_article
    @bottom_articles  = find_bottom_articles
  end


  private

  def find_candidates
    candidates = []

    candidates << FeatureCandidate::Slideshow.new(@category, exclude: @excludes)
    candidates << FeatureCandidate::Segment.new(@category, exclude: @excludes)

    candidates
  end

  def find_featured_object
    # Only select candidates which were given a score,
    # then reverse sort by score and return the first one's content
    @candidates.select(&:score).sort_by { |c| -c.score }.first.try(:content)
  end

  def find_top_article
    @articles.find { |a| !a.assets.empty? }
  end

  # Articles already get sorted in reverse chron on ContentBase.search
  # We could remove the @top_article check, but I guess leaving it in
  # doesn't hurt anything.
  def find_bottom_articles
    @top_article ? @articles.select { |a| a != @top_article } : @articles
  end
end
