class NewsStory < ActiveRecord::Base
  self.table_name = 'news_story'
  outpost_model
  has_secretary


  include Concern::Scopes::SinceScope
  include Concern::Scopes::PublishedScope
  include Concern::Associations::ContentAlarmAssociation
  include Concern::Associations::AudioAssociation
  include Concern::Associations::AssetAssociation
  include Concern::Associations::RelatedContentAssociation
  include Concern::Associations::RelatedLinksAssociation
  include Concern::Associations::BylinesAssociation
  include Concern::Associations::TagsAssociation
  include Concern::Associations::FeatureAssociation
  include Concern::Associations::CategoryAssociation
  include Concern::Associations::HomepageContentAssociation
  include Concern::Associations::QuoteAssociation
  include Concern::Associations::EditionsAssociation
  include Concern::Associations::VerticalArticleAssociation
  include Concern::Associations::ProgramArticleAssociation
  include Concern::Validations::ContentValidation
  include Concern::Callbacks::SetPublishedAtCallback
  include Concern::Callbacks::GenerateShortHeadlineCallback
  include Concern::Callbacks::GenerateTeaserCallback
  include Concern::Callbacks::GenerateSlugCallback
  #include Concern::Callbacks::CacheExpirationCallback
  include Concern::Callbacks::PublishNotificationCallback
  include Concern::Model::Searchable
  include Concern::Callbacks::HomepageCachingCallback
  include Concern::Callbacks::TouchCallback
  include Concern::Methods::ArticleStatuses
  include Concern::Methods::CommentMethods
  include Concern::Methods::AssetDisplayMethods
  include Concern::Sanitizers::Content
  include Concern::Associations::PmpContentAssociation::StoryProfile

  self.disqus_identifier_base = "news/story"
  self.public_route_key = "news_story"

  SOURCES = [
    ['KPCC',                        'kpcc'],
    ['KPCC & wires',                'kpcc_plus_wire'],
    ['AP',                          'ap'],
    ['KPCC wire services',          'kpcc_wire'],
    ['NPR',                         'npr'],
    ['NPR & wire services',         'npr_wire'],
    ['New America Media',           'new_america'],
    ['NPR & KPCC',                  'npr_kpcc'],
    ['Center for Health Reporting', 'chr'],
    ['Marketplace',                 'marketplace'],
    ['American Homefront Project',  'american_homefront_project']
  ]

  scope :with_article_includes, ->() { includes(:category,:assets,:audio,:tags,:bylines,bylines:[:user]) }


  def needs_validation?
    self.pending? || self.published?
  end

  def route_hash
    return {} if !self.persisted? || !self.persisted_record.published?
    {
      :year           => self.persisted_record.published_at.year.to_s,
      :month          => "%02d" % self.persisted_record.published_at.month,
      :day            => "%02d" % self.persisted_record.published_at.day,
      :id             => self.persisted_record.id.to_s,
      :slug           => self.persisted_record.slug,
      :trailing_slash => true
    }
  end


  def byline_extras
    Array(self.news_agency)
  end


  def to_article
    @to_article ||= Article.new({
      :original_object    => self,
      :id                 => self.obj_key,
      :title              => self.headline,
      :short_title        => self.short_headline,
      :public_datetime    => self.published_at,
      :teaser             => self.teaser,
      :body               => self.body,
      :category           => self.category,
      :assets             => self.assets.top,
      :audio              => self.audio.select(&:available?),
      :attributions       => self.bylines,
      :byline             => self.byline,
      :edit_path          => self.admin_edit_path,
      :public_path        => self.public_path,
      :tags               => self.tags,
      :feature            => self.feature,
      :created_at         => self.created_at,
      :updated_at         => self.updated_at,
      :published          => self.published?,
    })
  end


  def to_abstract
    @to_abstract ||= Abstract.new({
      :original_object        => self,
      :headline               => self.short_headline,
      :summary                => self.teaser,
      :source                 => "KPCC",
      :url                    => self.public_url,
      :assets                 => self.assets.top,
      :audio                  => self.audio.available,
      :category               => self.category,
      :article_published_at   => self.published_at
    })
  end

end
