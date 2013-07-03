class Outpost::ScheduleOccurrencesController < Outpost::ResourceController
  outpost_controller

  define_list do |l|
    l.default_order = "starts_at"
    l.default_sort_mode = "desc"
    l.per_page = 50
    
    l.column :title
    l.column :starts_at, sortable: true, default_sort_mode: :desc
    l.column :ends_at
    l.column :info_url, display: :display_link
    l.column :is_recurring?, header: "Recurring?", display: :display_boolean
  end
end
