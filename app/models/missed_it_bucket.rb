class MissedItBucket < ActiveRecord::Base
  self.table_name = "contentbase_misseditbucket"
  has_secretary
  
  #-----------
  # Administration
  administrate do
    define_list do
      column "id"
      column "title", linked: true
    end
  end
  
  #-----------
  # Association
  has_many :contents, class_name: "MissedItContent", foreign_key: "bucket_id", order: "position asc"
  
  #-----------
  # Validation
  validates :title, presence: true
  
  #-----------
  
  def self.content_key
    "missed_it"
  end
end
