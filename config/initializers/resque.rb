Resque.redis = "#{ENV["SCPRV4_RESQUE_HOST"] || Rails.application.secrets["resque"]}/resque:scprv4-#{Rails.env}"

Resque.after_fork do |job|
  # Every time a job is started, make sure the connection
  # to MySQL is okay. This avoids the "MySQL server has gone away"
  # error.
  ActiveRecord::Base.connection_pool.connections.each(&:verify!)
end
