module WP
  class Document
    attr_reader :title, :pubDate

    def initialize(file)
      @@doc ||= Nokogiri::XML(File.open(file))
      @title = @@doc.at_xpath("/rss/channel/title").content
      @pubDate = @@doc.at_xpath("/rss/channel/pubDate").content
    end

    def method_missing(method, *args, &block)
      instance_variable_get("@#{method}") || 
        instance_variable_set("@#{method}", ["WP", method.to_s.singularize.camelize].join("::").constantize.find(@@doc))
    end
  end
end
