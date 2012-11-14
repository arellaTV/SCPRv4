##
# AdminResource::Controller
#
module AdminResource
  module Controller
    extend ActiveSupport::Autoload
    extend ActiveSupport::Concern
    
    included do
      include AdminResource::Controller::Actions
    end
    
    autoload :Actions
    autoload :Helpers
  end # Controller
end # AdminResource