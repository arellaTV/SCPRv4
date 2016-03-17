module Concern::Model::Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    index_name "#{ES_PREFIX}-models"

    [:create,:update,:destroy].each do |a|
      after_commit on:a do
        async_index action: a.to_s
      end
    end

    def as_indexed_json(opts={})
      model = self.class.name.underscore
      h = as_json(opts)

      if h[ model ]
        {}.merge(h[ model ]).merge(h).except(model)
      else
        h
      end
    end

    # def to_article
    #   raise "#to_article method not implemented in model.  This is required for Article and indexing."
    # end

    def get_article
      ## retrieve article from content_base, else perform #to_article and index for future
      @get_article ||=
        if article = ContentBase.find(obj_key)
          article
        else
          async_index
          to_article
        end
    end

    def to_reference
      a = get_article
      { 
        id:              a.id, 
        public_path:     a.public_path, 
        title:           a.title, 
        short_title:     a.short_title,
        category:        a.category,
        public_datetime: a.public_datetime,
        has_audio?:      a.audio.any?,
        has_assets?:     a.assets.any?
      }
    end

    def async_index action: :create 
      Job::Indexer.enqueue(self.class.to_s, id, action)
    end

    def index
      # the models index (used in Outpost)
       __elasticsearch__.index_document

      # update the Article index if appropriate
      if respond_to?(:to_article)
        # eh, a one-item bulk operation? Not very bulk...
        ContentBase.es_client.bulk body: to_article.to_es_bulk_operation
      end   
    end

    private

    def to_article_called_more_than_twice?
      ## Not sure if there's a better way to do this, but this needs to
      ## be here to prevent infinite recursion with content that has both
      ## outgoing and incoming references.  Also not certain yet whether
      ## or not this needs to be the default.
      stack_level = caller.select{|s| s.include?("`to_article'") && s.include?(__FILE__)}.count
      stack_level < 3
    end

  end
end