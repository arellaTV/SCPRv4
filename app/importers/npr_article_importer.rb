class NprArticleImporter < Importer
  ORGANIZATION = "NPR"

  # An array of elements in an NPR::Story's 
  # +fullText+ attribute that we want to 
  # strip out before importing.
  UNWANTED_ELEMENTS = [ # By CSS
    '.storytitle',
    '#story-meta',
    '.bucketwrap',
    '#primaryaudio',
    'object'
  ]
  
  UNWANTED_PROPERTIES = [
    'class',
    'id',
    'data-metrics'
  ]

  # NPR IDs we're importing:
  # Reference: http://www.npr.org/api/inputReference.php  
  IMPORT_IDS = [
    '1001',      # News (topic)
    '93559255',  # Planet Money (blog)
    '93568166',  # Monkey See (blog)
    '15709577',  # All Songs Considered (blog)
    '173754155'  # Code Switch (blog)
  ]
  

  class << self
    def sync
      # The "id" parameter in this case is actually referencing a list.
      # Stories from the last hour are returned... be sure to run this script
      # more often than that!
      npr_stories = NPR::Story.where(
          :id     => IMPORT_IDS,
          :date   => (1.hour.ago..Time.now))
        .set(
          :requiredAssets   => 'text',
          :action           => "or")
        .order("date descending").limit(20).to_a
      
      log "#{npr_stories.size} NPR stories found from the past hour (max 20)"
      
      added = []
      npr_stories.each do |npr_story|
        # Check if this story was already cached - if not, cache it.
        if self.where(article_id: npr_story.id).first
          log "NPR Article ##{npr_story.id} already cached"
          next
        end

        cached_article = self.new(
          :article_id   => npr_story.id,
          :headline     => npr_story.title, 
          :teaser       => npr_story.teaser,
          :published_at => npr_story.pubDate,
          :url          => npr_story.link_for("html"),
          :is_new       => true
        )
        
        if cached_article.save
          added.push cached_article
          log "Saved NPR Story ##{npr_story.id} as NprArticle ##{cached_article.id}"
        else
          log "Couldn't save NPR Story ##{npr_story.id}"
        end
      end # each
      
      added
    end

    #-----------------------------

    def import(remote_article options={})
      import_to_class = options[:import_to_class] || "NewsStory"

      npr_story = NPR::Story.find_by_id(remote_article.article_id)
      return false if !npr_story
      
      # Make sure some text gets imported... 
      # if not then this whole process is useless.
      #
      # 1. If the +fullText+ exists, use it 
      #
      # 2. If the +fullText+ is blank, then try +textWithHtml+.
      # 
      # 3. If still nothing, then try just +text+.
      # 
      # 4. Failing all of that, we'll still import the story, 
      # but the body will just be blank.
      #
      text = begin
        if npr_story.textWithHtml.present?
          npr_story.textWithHtml.to_html
        elsif npr_story.text.present?
          npr_story.text.to_html
        end
      end
      
      #-------------------
      # Build the NewsStory from the API response
      article = import_to_class.constantize.new(
        :status         => ContentBase::STATUS_DRAFT,
        :headline       => npr_story.title,
        :teaser         => npr_story.teaser,
        :short_headline => npr_story.shortTitle.present? ? npr_story.shortTitle : npr_story.title,
        :body           => text
      )
      
      if article.is_a? NewsStory
        article.news_agency   = "NPR"
        article.source        = "npr"
      end
      
      #-------------------
      # Add in Bylines
      npr_story.bylines.each do |npr_byline|
        name = npr_byline.name.to_s
        
        if name.present?
          byline = ContentByline.new(name: name)
          article.bylines.push byline
        end
      end
      

      #-------------------
      # Add a related link pointing to this story at NPR
      if link = npr_story.link_for('html')
        related_link = RelatedLink.new(
          :link_type => "website", 
          :title     => "View this story at NPR",
          :url      => link
        )
        
        article.related_links.push related_link
      end
      
      #-------------------
      # Add in the primary asset if it exists
      if image = npr_story.primary_image
        
        # Try a few different crops to see which one is available.
        # We prefer the largest possible image with the least cropped out.
        crop = image.enlargement || image.crop("enlargment") || image.crop("standard") || image
        
        asset = AssetHost::Asset.create(
          :url     => crop.src,
          :title   => image.title,
          :caption => image.caption,
          :owner   => [image.producer, image.provider].join("/"),
          :note    => "Imported from NPR: #{npr_story.link_for('html')}"
        )

        if asset && asset.id
          content_asset = ContentAsset.new(
            :position   => 0,
            :asset_id   => asset.id,
            :caption    => image.caption
          )
          
          article.assets << content_asset
        end
      end
      
      
      #-------------------
      # Save the news story (including all associations),
      # set the RemoteArticle to `:is_new => false`,
      # and return the NewsStory that was generated.
      article.save!
      remote_article.update_attribute(:is_new, false)
      article
    end

    add_transaction_tracer :import, category: :task
  end
end
