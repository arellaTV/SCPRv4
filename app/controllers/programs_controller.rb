# This controller is annoying. The problem is that we have two different
# resources: KpccProgram, ExternalProgram, but they share the same URL
# namespace, so we have to send all traffic to this controller and then
# basically split every action into two.
class ProgramsController < ApplicationController

  include Concern::Controller::GetPopularArticles
  include Concern::Controller::ShowEpisodes
  extend Concern::Controller::Amp

  layout 'new/single', only: [:segment]

  before_filter :get_program, only: [:show, :episode, :archive, :featured_program, :featured_show]
  before_filter :get_popular_articles, only: [:featured_program, :segment]

  respond_to :html, :xml, :rss


  def index
    @featured_programs = KpccProgram.where(is_featured: true)
    @kpcc_programs     = KpccProgram.active.order("title")
    @external_programs = ExternalProgram.active.order("title")

    render layout: "application"
  end

  def show
    @episodes = @program.episodes.published

    if @program.is_a?(KpccProgram)
      # KPCC Program

      path = 'programs/kpcc/old/show'
      respond_with do |format|
        format.html do
          @current_episode = @episodes.first
          @episodes = (@current_episode ? @episodes.where.not(id:@current_episode.id) : @episodes).page(params[:page]).per(6)

          render path
        end
        format.xml do
          render path
        end
      end
    else
      @episodes = @episodes.page(params[:page]).per(6)

      # External Program
      respond_with do |format|
        format.html do
          render 'programs/external/show', layout: 'application'
        end
        format.xml do
          redirect_to @program.podcast_url
        end
      end
    end
  end

  def featured_program
    @segments = @program.segments.published.includes(:audio)
    @episodes = @program.episodes.published
    @featured_programs = KpccProgram.where.not(id: @program.id,is_featured: false)
    if @program.featured_articles.present?
      if @program.featured_articles.size > 1
        @featured_story = @program.featured_articles.first
        @subfeatured_story = @program.featured_articles.first(2)[1]
        @episodes = @episodes.where.not(id: [@featured_story.original_object.id, @episodes.first.id])
        if @featured_story.original_object.is_a?(ShowSegment)
          @segments = @segments - [@featured_story.original_object]
        end
      else
        @featured_story = @episodes.first
        @subfeatured_story = @program.featured_articles.first
        @episodes = @episodes.where.not(id: @episodes.first.id)
      end

    else
      @featured_story = @episodes.first
      @episodes = @episodes.where.not(id: @episodes.first.id)
    end
    respond_to do |format|
      format.html {
        render(
            :layout   => 'new/landing',
            :template => 'programs/kpcc/featured_program'
          )
      }

      format.xml { render 'programs/kpcc/old/show' }
    end
  end


  def segment
    @segment = ShowSegment.published.includes(:show).find(params[:id])
    @program = @kpcc_program = @segment.show
    @featured_programs = KpccProgram.where.not(id: @program.id, is_featured: false).first(4)

    # check whether this is the correct URL for the segment
    if request.original_fullpath != @segment.public_path
      redirect_to @segment.public_path and return
    end

    render 'programs/kpcc/segment' and return
  end

  amplify :segment, expose: {'@amp_record' => "@segment"}

  def episode
    if @program.is_a?(KpccProgram)
      @episode    = @program.episodes.find(params[:id])
      render_kpcc_episode
    end

    if @program.is_a?(ExternalProgram)
      @episode  = @program.episodes.find(params[:id])
      render_external_episode
    end
  end

  def featured_show
    if @program.is_a?(KpccProgram) && @program.is_featured?
      @view_type = params[:view]
      @segments = @program.segments.published
      @episodes = @program.episodes.published

      respond_with do |format|
        format.html do
          if @current_episode = @episodes.first
            @episodes = @episodes.where.not(id: @current_episode.id)

            segments = @current_episode.segments.published.to_a
            @segments = @segments.where.not(id: segments.map(&:id))
          end

          @segments = @segments.page(params[:page]).per(10)
          @episodes = @episodes.page(params[:page]).per(6)

          render 'programs/kpcc/old/featured_show'
        end

        format.xml { render 'programs/kpcc/old/show' }
      end

      return
    else
      redirect_to @program.public_path
    end
  end

  def archive
    @date = Time.zone.local(
      params[:archive]["date(1i)"].to_i,
      params[:archive]["date(2i)"].to_i,
      params[:archive]["date(3i)"].to_i
    )
    @episode = @program.episodes.for_air_date(@date).first

    if !@episode
      flash[:alert] = "There is no #{@program.title} " \
                      "episode for #{@date.strftime('%F')}."
      redirect_to featured_show_path(@program.slug, anchor: "archive")
    else
      redirect_to @episode.public_path
    end
  end

  def schedule
    @schedule_occurrences = ScheduleOccurrence.block(
      Time.zone.now.beginning_of_week, 1.week, true
    )

    # We can't cache all of them together, since there are too many.
    # So we'll just use the most recently updated one to cache.
    @cache_object = @schedule_occurrences.sort_by(&:updated_at).last
    render layout: "application"
  end


  private

  def get_program
    @program = KpccProgram.find_by_slug(params[:show]) ||
      ExternalProgram.find_by_slug(params[:show])


    if !@program
      render_error(404, ActionController::RoutingError.new("Not Found"))
      return false
    end
  end

end
