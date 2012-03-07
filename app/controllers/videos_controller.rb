class VideosController < ApplicationController
  layout "video"
  before_filter :get_latest_videos, only: [:index, :show]
  respond_to :html, :json, :js
  
  def index
    begin
      @video = VideoShell.published.first
    rescue
      redirect_to home_path
    end
  end
  
  def show
    begin
      @video = VideoShell.find(params[:id])
    rescue
      redirect_to video_index_path
    end
  end
  
  def list
    @videos = VideoShell.published
    @videos = @videos.paginate(page: params[:page], per_page: 9)
    respond_with @videos
  end
  
  protected
  def get_latest_videos
    @latest_videos = VideoShell.published.limit(4)
  end
end
