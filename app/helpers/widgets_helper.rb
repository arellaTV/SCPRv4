module WidgetsHelper

  def featured_comment(opts)
    opts = { :style => "default", :bucket => nil, :comment => nil }.merge(opts||{})
        
    comment = nil
    
    if opts[:comment]
      if opts[:comment].is_a?(FeaturedComment)
        comment = opts[:comment]
      else
        begin
          comment = FeaturedComment.find(opts[:comment])
        rescue
          return ''
        end
      end
    elsif opts[:bucket]
      bucket = FeaturedCommentBucket.find(opts[:bucket])
      comment = bucket.comments.published.first()
    else
      comment = FeaturedComment.published.first()
    end
    
    if comment && comment.content
      #begin
        return render(:partial => "shared/featured_comment/#{opts[:style]}", :object => comment, :as => :comment)
      #rescue
      #  return render(:partial => "shared/featured_comment/default", :object => comment, :as => :comment)          
      #end
    end
  end
  
  #----------
  
  def comment_count_for(object, options={})
    if object.present?
      render('shared/cwidgets/comment_count', { content: object, cssClass: "" }.merge!(options))
    end
  end
  
  def comment_count_link_for(object, options={})
    if object.present?
      options[:class] = "comment_link #{options[:class]}"
      link_to("Comments (#{object.comment_count})", object.link_path(anchor: "comments"), options)
    end
  end
  
  def comments_for(object, options={})
    if object.present?
      render('shared/cwidgets/comments', { content: object, cssClass: "" }.merge!(options))
    end
  end
  
  def related_content_for(object, options={})
    if object.present? and object.is_a?(ContentBase)
      if object.brels.present? or object.frels.present?
        render("shared/cwidgets/related_articles", { content: object }.merge!(options))
      end
    end
  end
  
  def related_links_for(object, options={}) # Takes any ContentBase object
    if object.present? and object.is_a?(ContentBase)
      if object.related_links.present?
        render "shared/cwidgets/related_links", { content: object }.merge!(options)
      end
    end
  end
  
  def article_meta_for(object, options={})
    render('shared/cwidgets/article_meta', { content: object }.merge!(options)) if object.present?
  end
  
  def social_tools_for(object, options={})
    if object.present?
      options[:path] ||= object.link_path if object.respond_to?(:link_path)
      render "shared/cwidgets/social_tools", { :content => object, cssClass: "" }.merge!(options)
    end
	end
  
end