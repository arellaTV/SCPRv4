class ContentShell < ActiveRecord::Base
  self.table_name = "contentbase_contentshell"
  outpost_model
  has_secretary


  include Concern::Scopes::SinceScope
  include Concern::Scopes::PublishedScope
  include Concern::Associations::ContentAlarmAssociation
  include Concern::Associations::AssetAssociation
  include Concern::Associations::BylinesAssociation
  include Concern::Associations::TagsAssociation
  include Concern::Associations::FeatureAssociation
  include Concern::Associations::CategoryAssociation
  include Concern::Associations::HomepageContentAssociation
  include Concern::Associations::FeaturedCommentAssociation
  include Concern::Associations::QuoteAssociation
  include Concern::Associations::MissedItContentAssociation
  include Concern::Associations::EditionsAssociation
  include Concern::Associations::VerticalArticleAssociation
  include Concern::Associations::EpisodeRundownAssociation
  include Concern::Associations::RelatedContentAssociation
  include Concern::Validations::PublishedAtValidation
  include Concern::Associations::PmpContentAssociation::StoryProfile
  #include Concern::Callbacks::CacheExpirationCallback
  include Concern::Callbacks::PublishNotificationCallback
  include Concern::Model::Searchable
  include Concern::Callbacks::HomepageCachingCallback
  include Concern::Callbacks::TouchCallback
  include Concern::Methods::ArticleStatuses
  include Concern::Sanitizers::Content
  include Concern::Sanitizers::Url

  validates :status, presence: true
  validates :headline, presence: true # always
  validates :body, presence: true, if: :should_validate?
  validates :url, url: true, presence: true, if: :should_validate?
  validates :site, presence: true, if: :should_validate?

  alias_attribute :teaser, :body
  alias_attribute :short_headline, :headline
  alias_attribute :public_datetime, :published_at

  scope :with_article_includes, ->() { includes(:assets,:category,:tags,:bylines,bylines:[:user]) }

  before_save ->{ sanitize_urls :url }

  class << self
    def sites_select_collection
      ContentShell.select("distinct site").order("site").map(&:site)
    end
  end


  def needs_validation?
    self.pending? || self.published?
  end


  # Override Outpost's routing methods for these
  def public_path(options={})
    self.public_url
  end

  def public_url(options={})
    self.url
  end


  def byline_extras
    [self.site]
  end


  def to_article
    @to_article ||= Article.new({
      :original_object    => self,
      :id                 => self.obj_key,
      :title              => self.headline,
      :short_title        => self.headline,
      :public_datetime    => self.published_at,
      :teaser             => self.body,
      :body               => self.body,
      :category           => self.category,
      :assets             => self.assets,
      :attributions       => self.bylines,
      :byline             => self.byline,
      :edit_path          => self.admin_edit_path,
      :public_path        => self.public_path,
      :tags               => self.tags,
      :feature            => self.feature,
      :created_at         => self.created_at,
      :updated_at         => self.updated_at,
      :published          => self.published?,
      :abstract           => self.abstract
    })
  end

  def to_abstract
    @to_abstract ||= Abstract.new({
      :original_object        => self,
      :headline               => self.short_headline,
      :summary                => !(self.abstract || "").empty? ? self.abstract : self.teaser,
      :source                 => !(self.abstract_source || "").blank? ? self.abstract_source : self.site,
      :url                    => self.url,
      :assets                 => self.assets,
      :category               => self.category,
      :article_published_at   => self.published_at
    })
  end
end
