task :scheduler => [:environment] do
  scheduler = Rufus::Scheduler.new

  # -- Content -- #

  scheduler.every '1m' do |job|
    Job::MastheadCache.enqueue()
  end

  scheduler.every '1m' do |job|
    ContentAlarm.fire_pending
  end

  scheduler.every '10m' do |job|
    Job::SyncAudio.enqueue ["AudioSync::Pending", "AudioSync::Program"]
  end

  scheduler.every '15m' do |job|
    Job::TwitterCache.enqueue()
  end

  # -- Caches -- #

  # most whatevers...
  scheduler.every '30m' do |job|
    Job::MostViewed.enqueue()
    Job::MostViewedBlogEntries.enqueue()
    Job::MostCommented.enqueue()
  end

  # -- Externals -- #

  # external NPR programs every hour
  scheduler.cron "0 * * * *" do |job|
    Job::SyncExternalPrograms.enqueue("npr-api")
  end

  # external RSS programs every four hours
  scheduler.cron "0 * * * *" do |job|
    Job::SyncExternalPrograms.enqueue("rss")
  end


  # marketplace every hour
  scheduler.cron "0 * * * *" do |job|
    Job::FetchMarketplaceArticles.enqueue()
  end

  # remote articles every 20 minutes
  scheduler.cron "*/20 * * * *" do |job|
    Job::SyncRemoteArticles.enqueue()
  end

  # Go!
  puts "Scheduler running."
  scheduler.join
end