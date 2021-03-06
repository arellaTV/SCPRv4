##
# CacheController
#
# Cache partials for content.
#
class CacheController < AbstractController::Base
  abstract!

  include AbstractController::Logger
  include AbstractController::Helpers
  include AbstractController::Translation
  include AbstractController::AssetPaths
  include Rails.application.routes.url_helpers
  include RenderAnywhere

  helper ApplicationHelper, UtilityHelper

  def render_view(options)
    render options.reverse_merge(layout:false)
  end

  # Write a partial's output to cache.
  #
  # Arguments:
  # * content: Array or content
  #            The content to be passed into the partial
  #            Passed in as local variable :content
  #            Local-var name can be overridden with the :local option
  # * partial: String
  #            The partial the render, relative to Rails.root
  # * cache_key: String
  #              The cache key to write to
  def cache(content, partial, cache_key, options={})
    options.reverse_merge!(local: :content)
    cached = render(partial: partial, object: content, as: options[:local])
    write(cache_key, cached)
  end

  def perform_caching
    false
  end

  #---------------------

  private

  def write(key, value)
    Cache.write(key, value)
    true
  end
end
