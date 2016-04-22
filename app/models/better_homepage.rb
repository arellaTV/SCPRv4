class BetterHomepage < ActiveRecord::Base
  outpost_model
  has_secretary
  has_status

  include Concern::Scopes::PublishedScope
  include Concern::Associations::ContentAlarmAssociation
  include Concern::Callbacks::SetPublishedAtCallback
  include Concern::Callbacks::PublishNotificationCallback
  include Concern::Model::Searchable
  include Concern::Callbacks::HomepageCachingCallback
  include Concern::Callbacks::TouchCallback

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
    s.text = "Live"
    s.published!
  end

  has_many :content,
    -> { order('position') },
    :class_name   => "HomepageContent",
    :dependent    => :destroy,
    :as           => :homepage

  accepts_json_input_for :content
  tracks_association :content

  validates \
    :status,
    presence: true

  def publish
    self.update_attributes(status: self.class.status_id(:live))
  end

  def articles
    @articles ||= self.content.includes(:content).map do |c|
      c.content.to_article
    end
  end

  def category_previews
    @category_previews ||= begin
      Category.previews(exclude: self.articles)
    end
  end

  private

  def build_content_association(content_hash, content)
    if content.published?
      HomepageContent.new(
        :position => content_hash["position"].to_i,
        :content  => content,
        :homepage => self
      )
    end
  end
end
