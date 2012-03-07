class ProgramsController < ApplicationController  
  before_filter :get_ambiguous_program, only: :show
  before_filter :get_featured_programs, only: :index
  #before_filter :get_program_segments, only: :show
  before_filter :get_kpcc_program, only: [:segment, :episode]
  
  def index
    @kpcc_programs = KpccProgram.active.order("title")
    @other_programs = OtherProgram.active.order("title")
    render :layout => "application"
  end
  
  #----------
  
  def show
    # @program gets set via the before_filter
    
    # if display_segments is set, load up paginated segments
    if @program.display_segments
      @segments = @program.segments.published.paginate(page: params[:page], per_page: 10)
    end
    
    # if we use episodes—but only if we don't also show segments—we load paginated episodes
    if @program.display_episodes && !@program.display_segments
      @episodes = @program.episodes.published.paginate(page: params[:page], per_page: 6)
    end
    
    if @program.is_a? KpccProgram
      render :action => "show"
    else
      render :action => "show_external"
    end
  end
  
  #----------
  
  def segment
    @segment = ShowSegment.published.find(params[:id])
    
    # check whether this is the correct URL for the segment
    if ( request.env['PATH_INFO'] =~ /\/$/ ? request.env['PATH_INFO'] : "#{request.env['PATH_INFO']}/" ) != @segment.link_path
      redirect_to @segment.link_path and return
    end
  end
  
  #----------
  
  def episode
    @episode = @program.episodes.published.where(air_date: date).first
  end
  
  protected
    def get_ambiguous_program
      @program = KpccProgram.find_by_slug(params[:show]) || OtherProgram.find_by_slug(params[:show])
      redirect_to programs_path if @program.blank?
    end
    
    def get_kpcc_program
      @program = KpccProgram.find_by_slug(params[:show])
      redirect_to programs_path if @program.blank?
    end
    
    def get_featured_programs
      @featured_programs = KpccProgram.where("slug IN (?)", KpccProgram::Featured)
    end
    
    def date # Might use this more than once?
      Date.new(params[:year].to_i,params[:month].to_i,params[:day].to_i)
    end
    
    def get_program_segments
      @segments = @program.segments.paginate(page: params[:segments_page], per_page: 10)
      rescue
        redirect_to programs_path
    end
end
