class AddPushBooleanToBreakingNewsAlerts < ActiveRecord::Migration
  def change
    add_column :layout_breakingnewsalert, :send_mobile_notification, :boolean, default: false
  end
end
