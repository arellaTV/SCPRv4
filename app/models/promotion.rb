class Promotion < ActiveRecord::Base
  outpost_model
  has_secretary
  
  #-------------
  # Validations
  validates_presence_of :title, :url
  
  #-------------
  # Sphinx
  define_index do
    indexes title, sortable: true
    indexes url

    has created_at
  end
  
  #-------------
  
  def asset
    if self.asset_id.present?
      @asset ||= Asset.find(self.asset_id)
    else
      false
    end
  end
end
