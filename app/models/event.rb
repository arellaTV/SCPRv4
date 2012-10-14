class Event < ActiveRecord::Base
  include Model::Validations::SlugValidation
  include Model::Associations::AudioAssociation
  include Model::Associations::AssetAssociation
  
  self.table_name  = 'events_event'
  self.primary_key = "id"
  ROUTE_KEY        = "event"
  
  acts_as_content published_at: false
  has_secretary
  
  ForumTypes = [
    "comm",
    "cult",
    "hall"
  ]
  
  EVENT_TYPES = [
      ['Forum: Community Engagement', 'comm'],
      ['Forum: Cultural',             'cult'],
      ['Forum: Town Hall',            'hall'],
      ['Sponsored',                   'spon'],
      ['Staff Picks',                 'pick']
  ]
  
  
  # -------------------
  # Administration
  administrate do |admin|
    admin.define_list do |list|
      list.order = "created_at desc"
      
      list.column "headline"
      list.column "starts_at"
      list.column "location_name", header: "Location"
      list.column "etype",         header: "Type"
      list.column "kpcc_event",    header: "KPCC Event?"
      list.column "is_published",  header: "Published?"
    end
  end


  # -------------------
  # Associations
  belongs_to :kpcc_program
  
  
  # -------------------
  # Validations
  validates :headline, presence: true
  validates :etype, :starts_at, :body, presence: true, if: :should_validate?
  validates :slug, unique_by_date: { scope: :starts_at, filter: :day, message: "has already been used for that start date." },
    if: :should_validate?
  
  def should_validate?
    published?
  end
  
  def published?
    !!is_published
  end
  
  
  # -------------------
  # Scopes
  scope :published,             -> { where(is_published: true) }
  scope :forum,                 -> { published.where("etype IN (?)", ForumTypes) }
  scope :sponsored,             -> { published.where("etype = ?", "spon") }
  
  scope :upcoming,              -> { published.where("starts_at > ?", Time.now).order("starts_at") }
  scope :upcoming_and_current,  -> { published.where("ends_at > :now or starts_at > :now", now: Time.now).order("starts_at") }
  scope :past,                  -> { published.where("ends_at < :now", now: Time.now).order("starts_at desc") }


  # -------------------
  
  def status
    is_published ? ContentBase::STATUS_LIVE : ContentBase::STATUS_DRAFT
  end
  
  # -------------------
  
  def self.sorted(events)
    events.sort { |a,b| a.sorter <=> b.sorter }
  end
  
  def sorter
    ongoing? ? ends_at : starts_at
  end
  
  # -------------------

  def ongoing?
    multiple_days? and current?
  end
  
  def multiple_days?
    minutes > 24*60
  end
  
  def minutes
    if self.ends_at.present?
      endt = self.ends_at
    else
      endt = self.starts_at.end_of_day
    end
    
    ((endt - starts_at) / 60).floor
  end
  
  # -------------------
  
  def self.closest
    upcoming.first
  end
  
  # -------------------
  
  def upcoming? # Still display maps, details, etc. if the event is currently happening
    starts_at > Time.now
  end
  
  def current?
    if ends_at.present?
      Time.now.between? starts_at, ends_at
    else
      Time.now.between? starts_at, starts_at.end_of_day
    end
  end

  #----------
  
  def is_forum_event?
    ForumTypes.include? self.etype
  end
  
  #----------
  
  def route_hash
    return {} if !self.published? || !self.persisted?
    {
      :year           => self.persisted_record.starts_at.year, 
      :month          => self.persisted_record.starts_at.month.to_s.sub(/^[^0]$/) { |n| "0#{n}" }, 
      :day            => self.persisted_record.starts_at.day.to_s.sub(/^[^0]$/) { |n| "0#{n}" },
      :slug           => self.persisted_record.slug,
      :trailing_slash => true
    }
  end
end
