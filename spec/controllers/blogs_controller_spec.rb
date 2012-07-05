require "spec_helper"

describe BlogsController do
  describe "GET /index" do    
    it "renders the application layout" do
      get :index
      response.should render_template "layouts/application"
    end
       
    it "assigns @blogs" do
      blog = create :blog
      get :index
      assigns(:blogs).should eq [blog]
    end
    
    it "doesn't assign @blog" do
      get :index
      assigns(:blog).should be_nil
    end
    
    it "orders @blogs by name" do
      get :index
      assigns(:blogs).to_sql.should match /order by name/i
    end
    
    it "only assigns active blogs to @blogs" do
      create :blog, is_active: false
      active_blog = create :blog, is_active: true
      get :index
      assigns(:blogs).should eq [active_blog]
    end
    
    it "assigns @news_blogs" do
      blog = create :blog, is_remote: false, is_news: true
      get :index
      assigns(:news_blogs).should eq [blog]
    end
    
    it "assigns @non_news_blogs" do
      blog = create :blog, is_remote: false, is_news: false
      get :index
      assigns(:non_news_blogs).should eq [blog]
    end
    
    it "assigns @remote_blogs" do
      blog = create :blog, is_remote: true
      get :index
      assigns(:remote_blogs).should eq [blog]
    end
    
    it "orders @remote_blogs by name" do
      create :blog, is_remote: true
      get :index
      assigns(:remote_blogs).to_sql.should match /order by name/i
    end
  end
  
  describe "GET /show" do
    describe "for invalid blogs" do
      it "responds with RoutingError on invalid slug" do
        blog = create :blog
        -> { get :show, blog: "nonsense" }.should raise_error ActionController::RoutingError
      end
  
      it "responds with RoutingError for a remote blog" do
        blog = create :blog, is_remote: true
        -> { get :show, blog: blog.slug }.should raise_error ActionController::RoutingError
      end
    end
    
    describe "for valid blogs" do
      describe "with XML" do
        it "renders xml template when requested" do
          blog = create :blog
          get :show, blog: blog.slug, format: :xml
          response.should render_template 'blogs/show', format: :xml
        end
      end
      
      it "responds with success" do
        blog = create :blog
        get :show, blog: blog.slug
        response.should be_success
      end
    
      it "assigns @blog" do
        blog = create :blog, is_remote: false
        get :show, blog: blog.slug
        assigns(:blog).should eq blog
      end
    
      it "assigns @entries" do
        blog = create :blog
        get :show, blog: blog.slug
        assigns(:entries).should_not be_nil
      end
    
      it "only gets published entries" do
        blog = create :blog
        entry_pending = create :blog_entry, blog: blog, status: ContentBase::STATUS_PENDING
        entry_published = create :blog_entry, blog: blog, status: ContentBase::STATUS_LIVE
        get :show, blog: blog.slug
        assigns(:entries).should eq [entry_published]
      end
    
      it "paginates" do
        blog = create(:blog, entry_count: 10)
        get :show, blog: blog.slug, page: 1
        assigns(:entries).size.should be < 10
      end
    end
  end
  
  describe "GET /blog_tags" do
    it "responds with success" do
      blog = create :blog
      get :blog_tags, blog: blog.slug
      response.should be_success
    end
    
    it "assigns @blog" do
      blog = create :blog, is_remote: false
      get :show, blog: blog.slug
      assigns(:blog).should eq blog
    end
    
    it "assigns @recent" do
      blog = create :blog
      get :blog_tags, blog: blog.slug
      assigns(:recent).should_not be_nil
    end
    
    it "assigns blog tags to @recent" do
      pending "Need Tag factory"
    end
    
    it "orders tags by blog entry published desc" do
      blog = create :blog
      get :blog_tags, blog: blog.slug
      assigns(:recent).to_sql.should match /blogs_entry.published_at desc/i
    end
  end
  
  describe "GET /blog_tagged" do
    it "responds with success" do
      pending "Need Tag factory"
      blog = create :blog
      get :blog_tagged, blog: blog.slug, tag: "news"
      response.should be_success
    end
    
    it "redirects if tag doesn't exist" do
      blog = create :blog
      get :blog_tagged, blog: blog.slug, tag: "nonsense"
      response.should redirect_to blog_tags_path(blog.slug)
    end
    
    it "assigns @tag" do
      pending "Need Tag factory"
      blog = create :blog
      get :blog_tagged, blog: blog.slug, tag: "news"
      assigns(:tag).should_not be_nil
    end
  end
  
  describe "load_blog" do
    before :all do
      @blog = create :blog
      entry_published = create :blog_entry, blog: @blog
      p = entry_published.published_at
      @entry_attr = { blog: @blog.slug, tag: "news", id: entry_published.id, slug: entry_published.slug }.merge(date_path(p))
    end
    
    after :all do
      @blog = nil
    end
    
    %w{ show entry blog_tags blog_tagged }.each do |action|
      it "assigns @blog for #{action}" do
        get action, @entry_attr
        assigns(:blog).should eq @blog
      end

      it "assigns @authors for #{action}" do
        get action, @entry_attr
        assigns(:authors).should_not be_nil
      end
      
      it "raises RoutingEror if blog isn't found" do
        -> { get action, @entry_attr.merge(blog: "nonsense") }.should raise_error ActionController::RoutingError
      end
    end
    
    %w{ index }.each do |action|
      it "does not assign @blog for #{action}" do
        get action, blog: @blog.slug
        assigns(:blog).should be_nil
      end

      it "does not assign @authors for #{action}" do
        get action, blog: @blog.slug
        assigns(:authors).should be_nil
      end      
    end
  end
  
  describe "GET /entry" do
    describe "for invalid entry" do
      it "raises a routing error for unpublished" do
        entry = create :blog_entry, status: ContentBase::STATUS_PENDING
        -> {
          get :entry, { blog: entry.blog.slug, id: entry.id, slug: entry.slug }.merge!(date_path(entry.published_at))
        }.should raise_error ActionController::RoutingError
      end
      
      it "raises a routing error for invalid ID" do
        entry = create :blog_entry
        -> {
          get :entry, { blog: entry.blog.slug, id: "999999", slug: entry.slug }.merge!(date_path(entry.published_at))
        }.should raise_error ActionController::RoutingError
      end
    end
    
    describe "for valid entry" do
      let(:entry) { create :blog_entry }
      
      before :each do
        get :entry, { blog: entry.blog.slug, id: entry.id, slug: entry.slug }.merge!(date_path(entry.published_at))
      end
      
      it "responds with success" do
        response.should be_success
      end
    
      it "assigns @entry" do
        assigns(:entry).should eq entry
      end
    end
  end
end