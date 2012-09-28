class PijQuery < ActiveRecord::Base
  include Model::Scopes::SinceScope
  include Model::Associations::AssetAssociation

  self.table_name = 'pij_query'
  ROUTE_KEY       = "pij_query"
  
  acts_as_content comments: false, has_status: false, published_at: false
  has_secretary
  
  QUERY_TYPES = [
    ["Evergreen",             "evergreen"],
    ["News",                  "news"],
    ["Internal (not listed)", "utility"]
  ]
  
  #------------
  # Administration
  administrate do |admin|
    admin.define_list do |list|
      list.column "headline"
      list.column "slug"
      list.column "query_type"
      list.column "is_active",    header: "Active?"
      list.column "is_featured",  header: "Featured?"
      list.column "published_at"
    end
  end
  
  
  #------------
  # Scopes  
  scope :news,          where(query_type: "news")
  scope :evergreen,     where(query_type: "evergreen")
  scope :featured,      where(is_featured: true)
  scope :not_featured,  where(is_featured: false)

  scope :visible, -> { where(
    'is_active = :is_active and published_at < :time and ' \
    '(expires_at is null or expires_at > :time)', 
    is_active: true, time: Time.now
  ).order("published_at desc") }
  
  
  #------------
  # Validation
  validates :slug,        presence: true, uniqueness: true
  validates :query_type,  presence: true
  validates :query_url,   presence: true
  validates :headline,    presence: true
  validates :form_height, presence: true

  #------------  
  
  def published?
    !!is_active
  end

  #------------  
  
  def route_hash
    return {} if !self.published? || !self.persisted?
    {
      :slug           => self.persisted_record.slug,
      :trailing_slash => true
    }
  end
end
