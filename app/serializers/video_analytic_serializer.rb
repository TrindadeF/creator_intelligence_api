class VideoAnalyticSerializer < Blueprinter::Base
  identifier :id

  fields :views, :likes, :comments, :shares, :saves,
         :watch_time, :avg_watch_time, :retention_rate,
         :completion_rate, :engagement_rate, :followers_gained,
         :revenue, :collected_at
end
