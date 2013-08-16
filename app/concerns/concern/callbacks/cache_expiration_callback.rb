##
# CacheExpirationCallback
#
# Expires cache
# Requires the methods defined in PublishingMethods
#
module Concern
  module Callbacks
    module CacheExpirationCallback
      extend ActiveSupport::Concern

      included do
        include Concern::Methods::PublishingMethods
        after_commit :expire_cache
      end

      private

      def expire_cache
        # If we are going from "published" -> "published" (still),
        # or we are going from "published" -> "unpublished",
        # just expire this object
        if (self.published? && !self.publishing?) || self.unpublishing?
          Rails.cache.expire_obj(self)
        end

        # If we are going from "not published" -> "published".
        # Expire :new keys for the object's class and contentbase
        if self.publishing?
          Rails.cache.expire_obj([self.class.content_key, "new"].join(":"))
          Rails.cache.expire_obj("contentbase:new")
        end
      end
    end # CacheExpiration
  end # Callbacks
end # Concern
