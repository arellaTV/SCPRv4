class FeaturedComment < ActiveRecord::Base
  include Model::Methods::StatusMethods
  include Model::Methods::PublishingMethods
  include Model::Callbacks::SetPublishedAtCallback
  include Model::Associations::ContentAlarmAssociation
  
  self.table_name = 'contentbase_featuredcomment'
  has_secretary
  
  #----------------
  # Administration
  administrate do
    define_list do
      order = "published_at desc"

      column :bucket
      column :content
      column :username, linked: true
      column :excerpt
      column :status
      column :published_at
    end
  end
  
  
  #----------------
  # Associations
  map_content_type_for_django
  belongs_to :content, polymorphic: true
  belongs_to :bucket, class_name: "FeaturedCommentBucket"
  
  
  #----------------
  # Scopes
  scope :published, where(status: ContentBase::STATUS_LIVE).order("published_at desc")
  
  
  #----------------
  # Validation
  validates :username, :status, presence: true
  validates :excerpt, :bucket_id, :content_id, :content_type, presence: true, if: -> { self.should_validate? }
  
  
  def title
    "Featured Comment (for #{content.obj_key})"
  end

  #----------------
  
  def should_validate?
    pending? or published?
  end
end
