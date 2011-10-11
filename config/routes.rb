Scprv4::Application.routes.draw do
  
  match '/news/:year/:month/:day/:id/:slug' => 'news#story', :as => :story, :constraints => { :year => /\d{4}/, :month => /\d{2}/, :day => /\d{2}/, :id => /\d+/, :slug => /[\w_-]+/}
  
end
