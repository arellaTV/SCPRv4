##
# AssetAssociation
#
# Association for Asset
#
module Model
  module Associations
    module AssetAssociation
      extend ActiveSupport::Concern
      
      included do
        has_many :assets, class_name: "ContentAsset", as: :content, order: "asset_order", dependent: :destroy
        accepts_nested_attributes_for :assets, allow_destroy: true        
      end
    end
  end
end
