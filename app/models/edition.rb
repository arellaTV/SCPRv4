# A collection of items, which are meant to be represented
# as Abstracts (although not all of them will actually be an Abstract object).
#
# This model was created originally for the mobile application,
# but there's no reason it couldn't also be presented on the
# website if there was a place out for it.
class Edition < ActiveRecord::Base
  outpost_model
  has_secretary
  has_status
  has_many :eloqua_emails, as: :emailable

  include Concern::Associations::ContentAlarmAssociation
  include Concern::Callbacks::SetPublishedAtCallback
  include Concern::Callbacks::TouchCallback
  include Concern::Model::Searchable
  include Concern::Scopes::PublishedScope


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

  SHORT_LIST_TYPES = {
    'am-edition'      => 'A.M. Edition',
    'pm-edition'      => 'P.M. Edition',
    'weekend-reads' => 'Weekend Reads'
  }

  scope :recently, ->{ where("published_at > ?", 3.hours.ago) }

  has_many :slots,
    -> { order('position') },
    :class_name   => "EditionSlot",
    :dependent    => :destroy

  accepts_json_input_for :slots


  validates :status, presence: true
  validates :title,
    :presence   => true,
    :if         => :should_validate?

  after_save :send_shortlist_email, if: :should_send_shortlist_email?
  after_save :send_monday_email, if: :should_send_monday_email?

  class << self
    def titles_collection
      self.where(status: self.status_id(:live))
      .select('distinct title').order('title').map(&:title)
    end

    def slug_select_collection
      SHORT_LIST_TYPES.map { |k,v| [v.titleize, k] }
    end
  end

  self.public_route_key = "short_list"

  def short_list_type
    SHORT_LIST_TYPES[self.slug]
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

  def needs_validation?
    self.pending? || self.published?
  end


  # Returns an array of Abstract objects
  # by mapping all of the items to Abstract objects.
  def abstracts
    @abstracts ||= self.slots.includes(:item).map { |slot|
      slot.item.to_abstract
    }
  end

  def articles
    @articles ||= self.slots.includes(:item).map { |slot|
      slot.item.to_article
    }
  end


  def publish
    self.update_attributes(status: self.class.status_id(:live))
  end

  def sister_editions
    self.class.published.where.not(id: self.id).first(4)
  end

  def send_shortlist_email
    subject = "The Short List: #{self.title}"
    eloqua_emails.create({
      :html_template   => "/editions/email/template",
      :plain_text_template   => "/editions/email/template",
      :name        => "[scpr-edition] #{self.title[0..30]}",
      :description => "SCPR Short List",
      :subject     => subject,
      :email       => "theshortlist@scpr.org",
      :email_type  => "shortlist"
    })
  end

  def send_monday_email
    subject = "The Short List: #{self.title}"
    eloqua_emails.create({
      :html_template   => "/editions/email/template",
      :plain_text_template   => "/editions/email/template",
      :name        => "[scpr-edition] #{self.title[0..30]}",
      :description => "SCPR Short List",
      :subject     => subject,
      :email       => "theshortlist@scpr.org",
      :email_type  => "shortlist"
    })
  end

  def shortlist_email_sent?
    email_sent?("shortlist") || email_sent
  end

  def monday_email_sent?
    email_sent? "monday"
  end

  def view
    @view ||= CacheController.new
  end

  def email_sent? email_type
    (eloqua_emails.where(email_type: email_type).first || Missing).sent?
  end

  private

  # We can't use `publishing?` here because this gets checked in
  # a background worker.
  def should_send_shortlist_email?
    published? && !shortlist_email_sent?
  end

  def should_send_monday_email?
    published? && !monday_email_sent? && Date.today.monday?
  end

  def build_slot_association(slot_hash, item)
    if item.published?
      EditionSlot.new(
        :position   => slot_hash["position"].to_i,
        :item       => item,
        :edition    => self
      )
    end
  end
end
