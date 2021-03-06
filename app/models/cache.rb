class Cache < ActiveRecord::Base
  class << self
    def read key
      if value = Rails.cache.read(key)
        value
      elsif value = find_by(key: key).try(:value)
        Rails.cache.write key, value
        value
      end
    end
    def write key, value
      Rails.cache.write(key, value)
      where(key: key).first_or_initialize.update(value: value)
      value
    end
    def clear
      delete_all
    end
  end

  class MarshalSerializer
    class << self
      include Marshal
      def load string
        super if string
      end
      def dump string
        super if string
      end
    end
  end

  serialize :value, MarshalSerializer
end
