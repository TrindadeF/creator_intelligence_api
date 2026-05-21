module Analytics
  class IngestVideoAnalyticsJob < ApplicationJob
    queue_as :default

    def perform(video_id, analytics_data)
      video = Video.find(video_id)

      VideoAnalytic.create!(
        video: video,
        views: analytics_data["views"] || 0,
        likes: analytics_data["likes"] || 0,
        comments: analytics_data["comments"] || 0,
        shares: analytics_data["shares"] || 0,
        saves: analytics_data["saves"] || 0,
        watch_time: analytics_data["watch_time"] || 0,
        avg_watch_time: analytics_data["avg_watch_time"] || 0,
        retention_rate: analytics_data["retention_rate"] || 0,
        completion_rate: analytics_data["completion_rate"] || 0,
        engagement_rate: analytics_data["engagement_rate"] || calculate_engagement(analytics_data),
        followers_gained: analytics_data["followers_gained"] || 0,
        revenue: analytics_data["revenue"] || 0,
        collected_at: analytics_data["collected_at"] || Time.current,
        raw_data: analytics_data
      )

      Rails.logger.info("[IngestVideoAnalyticsJob] Ingested analytics for video #{video_id}")
    end

    private

    def calculate_engagement(data)
      views = data["views"].to_i
      return 0.0 if views.zero?

      interactions = data["likes"].to_i + data["comments"].to_i + data["shares"].to_i + data["saves"].to_i
      ((interactions.to_f / views) * 100).round(2)
    end
  end
end
