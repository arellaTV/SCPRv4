class MissedItContent < ActiveRecord::Base
  include Outpost::Aggregator::SimpleJson

  self.table_name = "contentbase_misseditcontent"
  self.versioned_attributes = ["content_type", "content_id", "position"]

  # FIXME: Remove reference to ContentBase.
  # See HomepageContent for explanation.
  belongs_to :content,
    :polymorphic    => true,
    :conditions     => { status: ContentBase::STATUS_LIVE }

  belongs_to :missed_it_bucket, foreign_key: "bucket_id"
end
