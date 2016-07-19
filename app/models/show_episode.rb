class ShowEpisode < ActiveRecord::Base
  self.table_name = "shows_episode"
  outpost_model
  has_secretary
  has_status


  include Concern::Scopes::SinceScope
  include Concern::Associations::ContentAlarmAssociation
  include Concern::Associations::AudioAssociation
  include Concern::Associations::AssetAssociation
  include Concern::Associations::RelatedContentAssociation
  include Concern::Associations::RelatedLinksAssociation
  include Concern::Associations::BylinesAssociation
  include Concern::Associations::EditionsAssociation
  include Concern::Associations::PmpContentAssociation::StoryProfile
  include Concern::Associations::EpisodeRundownAssociation
  include Concern::Callbacks::SetPublishedAtCallback
  #include Concern::Callbacks::CacheExpirationCallback
  include Concern::Callbacks::PublishNotificationCallback
  include Concern::Model::Searchable
  include Concern::Callbacks::TouchCallback
  include Concern::Methods::CommentMethods
  include Concern::Methods::AssetDisplayMethods

  alias_attribute :title, :headline

  self.public_route_key = "episode"

  scope :with_article_includes, ->() { includes(:assets,:audio,:show) }

  status :killed do |s|
    s.id = -1
    s.text = "Killed"
    s.unpublished!
  end

  status :draft do |s|
    s.id = 0
    s.text = "Draft"
    s.unpublished!
  end

  status :pending do |s|
    s.id = 3
    s.text = "Pending"
    s.pending!
  end

  status :live do |s|
    s.id = 5
    s.text = "Published"
    s.published!
  end


  scope :published, -> {
    where(status: self.status_id(:live))
    .order("air_date desc, published_at desc")
  }

  scope :upcoming, -> {
    where(status: self.status_id(:pending))
    .where("air_date >= ?", Date.today)
    .order("air_date asc")
  }

  scope :for_air_date, ->(date_or_time) {
    where("DATE(air_date) = DATE(?)", date_or_time)
  }

  belongs_to :show,
    :class_name  => "KpccProgram",
    :touch       => true

  has_many :rundowns,
    class_name:   "ShowRundown",
    foreign_key:  "episode_id",
    inverse_of:   :episode,
    dependent:    :destroy,
    before_add:   :set_rundown_position

  ## Rundown type relations

  [:show_segments,:news_stories,:content_shells,:blogs,:show_episodes,:abstracts,:events,:pij_queries].each do |content_type|
    model_name = content_type.to_s.singularize.camelize
    has_many content_type,
      -> { where('shows_rundown.content_type' => model_name).order('shows_rundown.position') },
      :through        => :rundowns,
      :source         => :content,
      :source_type    => model_name
  end

  alias_attribute :segments, :show_segments


  accepts_json_input_for :rundowns
  tracks_association :rundowns


  validates :show, presence: true
  validates :status, presence: true
  validates :teaser, presence: true, if: :should_validate?
  validates :air_date, presence: true, if: :should_validate?

  before_save :generate_headline,
    :if => -> { self.headline.blank? }

  before_save :generate_body, if: -> { self.body.blank? && should_validate? }


  def needs_validation?
    self.pending? || self.published?
  end

  def publish
    self.update_attributes(status: self.class.status_id(:live))
  end

  def content
    rundowns.includes(:content).map(&:content)
  end

  def published_content
    content.select(&:published?)
  end

  def to_article
    return nil if !self.show
    related_content = to_article_called_more_than_twice? ? [] : self.published_content.map(&:get_article).map(&:to_reference)
    @to_article ||= Article.new({
      :original_object    => self,
      :id                 => self.obj_key,
      :title              => self.headline,
      :short_title        => self.headline,
      :public_datetime    => self.air_date,
      :body               => self.body,
      :teaser             => self.teaser,
      :assets             => self.assets.top,
      :audio              => self.audio.select(&:available?),
      :byline             => self.show.title,
      :edit_path          => self.admin_edit_path,
      :public_path        => self.public_path,
      :created_at         => self.created_at,
      :updated_at         => self.updated_at,
      :published          => self.published?,
      :show               => self.show,
      :related_content    => related_content,
      :links              => related_links.map(&:to_hash),
      :asset_display      => asset_display,
      :disqus_identifier  => self.disqus_identifier,
      :abstract           => self.abstract
    })
  end

  def route_hash
    return {} if !self.persisted? || !self.persisted_record.published?
    {
      :show           => self.persisted_record.show.slug,
      :year           => self.persisted_record.air_date.year.to_s,
      :month          => "%02d" % self.persisted_record.air_date.month,
      :day            => "%02d" % self.persisted_record.air_date.day,
      :id             => self.id.to_s,
      :trailing_slash => true
    }
  end

  def to_episode
    @to_episode ||= Episode.new({
      :original_object    => self,
      :id                 => self.obj_key,
      :title              => self.headline,
      :summary            => self.teaser,
      :air_date           => self.air_date,
      :assets             => self.assets.top,
      :audio              => self.audio.available,
      :program            => self.show,
      :segments           => self.segments.published.map(&:get_article),
      :content            => self.published_content.map(&:get_article)
    })
  end

  private

  def generate_headline
    if self.air_date.present? && self.show.present?
      self.headline = "#{self.show.title} for " \
        "#{self.air_date.strftime("%B %-d, %Y")}"
    end
  end

  def generate_body
    self.body = self.teaser
  end

  def build_rundown_association(rundown_hash, segment)
    ShowRundown.new(
      :position => rundown_hash["position"].to_i,
      :content => segment
    )
  end
end