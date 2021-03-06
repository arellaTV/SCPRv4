module Job
  class MostCommented < Base
    @priority = :low

    DISQUS_ROOT           = "https://disqus.com"
    DISQUS_POPULAR_PATH   = "/api/3.0/threads/listPopular.json"


    class << self
      def perform
        task = new("kpcc", "3d", Rails.configuration.x.api.disqus.api_key)

        comments  = task.fetch
        articles  = task.parse(comments).map(&:to_article)

        Cache.write("popular/commented", articles)

        self.cache(articles,
          "/shared/widgets/cached/popular",
          "views/popular/commented",
          local: :articles
        )
      end
    end



    def initialize(forum, interval, api_key)
      @forum    = forum
      @interval = interval
      @api_key  = api_key
    end


    def fetch
      response = connection.get do |request|
        request.url DISQUS_POPULAR_PATH, {
          :forum    => @forum,
          :interval => @interval,
          :api_key  => @api_key
        }
      end

      response
    end

    add_transaction_tracer :fetch, category: :task


    def parse(response)
      articles = []

      response.body['response'].each do |thread|
        if article = Concern::Methods::CommentMethods.obj_by_disqus_identifier(
          thread['identifiers'].first
        )
          self.log "Content: #{article.obj_key}, Count: #{thread['posts']}"
          articles.push(article) if article.published?
        end
      end

      articles
    end

    add_transaction_tracer :parse, category: :task


    private

    def connection
      @connection ||= begin
        options = {
          :headers => {
            'Accept'        => "application/json",
            'User-Agent'    => "SCPR.org"
          },
          :ssl     => { verify: false },
          :url     => DISQUS_ROOT
        }

        Faraday.new(options) do |builder|
          builder.use Faraday::Response::ParseJson
          builder.adapter Faraday.default_adapter
        end
      end
    end
  end # MostCommented
end # Job
