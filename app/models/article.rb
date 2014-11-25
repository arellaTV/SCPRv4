require 'zlib'

# An article is an abstract object, which is not persisted,
# but rather meant to be built manually from the attributes
# of another object.
#
# An Article should be the publc API for the parts of our
# presentational layer which mix different types of content.
# So in the areas where we're displaying blog entries, news
# stories, events, etc. all together, we shouldn't have to
# worry about whether one of the classes has defined an
# "audio" instance method, for example. We just coerce
# everything into an Article, and then *know* that it will
# work. This eliminates a lot of the "fakery" going on in
# our classes - stuff like `def teaser; self.body; end`.
#
# This also makes it super-easy to mix any content into the
# normal flow of things. If one day we decided that Bios
# should show up in the normal rotation on the homepage
# (this is a contrived example to illustrate the point),
# it would be a simple matter of defining a `to_article`
# instance method on the Bio class. How a Bio gets coerced
# into an Article is up to the developer.
#
# An Article object doesn't do anything fancy. It just acts
# exactly the way we need it to.
#
# This should pretty much match up with what our client API
# response is, but it doesn't necessarily have to.
class Article
  #include Concern::Methods::AbstractModelMethods
  include ActiveModel::Model

  attr_accessor \
    :original_object,
    :id,
    :title,
    :short_title,
    :public_datetime,
    :teaser,
    :body,
    :category,
    :assets,
    :audio,
    :attributions,
    :byline,
    :edit_path,
    :public_path,
    :tags,
    :feature,
    :created_at,
    :updated_at,
    :published,
    :blog,
    :show

  def initialize(attributes={})
    super

    #@assets           = Array(attributes[:assets])
    #@audio            = Array(attributes[:audio])
    #@attributions     = Array(attributes[:attributions])
    #@tags             = Array(attributes[:tags])
  end


  def to_article
    self
  end

  def to_abstract
    @to_abstract ||= Abstract.new({
      :original_object        => self,
      :headline               => self.title,
      :summary                => self.teaser,
      :source                 => self.byline,
      :url                    => self.public_url,
      :assets                 => self.assets,
      :audio                  => self.audio,
      :category               => self.category,
      :article_published_at   => self.public_datetime
    })
  end

  def original_object
    @original_object ||= Outpost.obj_by_key(self.id)
  end

  def obj_key
    self.id
  end

  def obj_class
    if @original_object
      @original_object.class.name.underscore
    else
      self.id.split("-")[0]
    end
  end

  def cache_key
    "#{self.id}-#{ self.updated_at.to_i }"
  end

  def public_url
    "http://#{Rails.application.default_url_options[:host]}#{self.public_path}"
  end

  def edit_url
    "http://#{Rails.application.default_url_options[:host]}#{self.edit_path}"
  end

  def asset
    @asset ||= self.assets.first || AssetHost::Asset::Fallback.new
  end

  def feature
    @feature ? ArticleFeature.find_by_key(@feature) : nil
  end

  def obj_key_crc32
    @obj_key_crc32 ||= Zlib.crc32(self.id)
  end

  # -- getters -- #

  def assets
    (@assets||[]).collect do |a|
      ContentAsset.new(asset_id:a.asset_id,caption:a.caption,position:a.position)
    end
  end

  def tags
    (@tags||[]).collect do |t|
      Tag.new(slug:t.slug,title:t.title)
    end
  end

  # -- setters -- #

  def assets=(assets)
    @assets = (assets||[]).collect do |a|
      Hashie::Mash.new(asset_id:a.asset_id, caption:a.caption, position:a.position)
    end
  end

  def audio=(audio)
    @audio = (audio||[]).collect do |a|
      Hashie::Mash.new(description:a.description, byline:a.byline, url:a.url)
    end
  end

  def category=(category)
    @category =  category ? Hashie::Mash.new(id:category.id, slug:category.slug) : nil
  end

  def tags=(tags)
    @tags = (tags||[]).collect do |t|
      Hashie::Mash.new(slug:t.slug, title:t.title)
    end
  end

  def blog=(blog)
    @blog = blog ? Hashie::Mash.new( id:blog.id, slug:blog.slug, name:blog.name ) : nil
  end

  def show=(show)
    @show = show ? Hashie::Mash.new( id:show.id, slug:show.slug, title:show.title ) : nil
  end

  def attributions=(bylines)
    @attributions = (bylines||[]).collect do |a|
      if a.is_a? ContentByline
        Hashie::Mash.new(name:a.display_name, id:a.user_id, role:a.role)
      else
        Hashie::Mash.new(name:a.name,id:a.id,role:a.role)
      end
    end
  end

  def feature=(feature)
    f = nil

    if feature.is_a?(ArticleFeature)
      f = feature.key
    elsif feature.is_a?(String)
      f = feature
    else
      f = nil
    end

    @feature = f
  end

  def to_hash
    {
      obj_key:          @id,
      class:            self.obj_class,
      title:            @title,
      short_title:      @short_title,
      public_datetime:  @public_datetime,
      teaser:           @teaser,
      body:             @body,
      category:         @category,
      byline:           @byline,
      attributions:     @attributions,
      feature:          @feature,
      tags:             @tags,
      assets:           @assets,
      audio:            @audio,
      published:        @published,
      created_at:       @created_at,
      updated_at:       @updated_at,
      edit_path:        @edit_path,
      public_path:      @public_path,
      blog:             @blog,
      show:             @show,
    }
  end
end
