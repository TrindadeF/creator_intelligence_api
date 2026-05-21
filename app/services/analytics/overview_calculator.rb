module Analytics
  class OverviewCalculator
    def initialize(user:, period: 30)
      @user = user
      @period = period
      @start_date = @period.days.ago
      @end_date = Time.current
    end

    def call
      {
        period_days: @period,
        summary: calculate_summary,
        growth: calculate_growth,
        top_videos: top_performing_videos,
        recent_insights: recent_insights
      }
    end

    private

    def calculate_summary
      analytics = VideoAnalytic
        .joins(video: :user)
        .where(users: { id: @user.id })
        .where(collected_at: @start_date..@end_date)

      {
        total_views: analytics.sum(:views),
        total_likes: analytics.sum(:likes),
        total_comments: analytics.sum(:comments),
        total_shares: analytics.sum(:shares),
        avg_engagement_rate: analytics.average(:engagement_rate)&.round(2) || 0,
        total_videos: @user.videos.published.count,
        videos_in_period: @user.videos.published.where(published_at: @start_date..@end_date).count
      }
    end

    def calculate_growth
      current_period_views = VideoAnalytic
        .joins(video: :user)
        .where(users: { id: @user.id })
        .where(collected_at: @start_date..@end_date)
        .sum(:views)

      previous_period_views = VideoAnalytic
        .joins(video: :user)
        .where(users: { id: @user.id })
        .where(collected_at: (@period * 2).days.ago..@start_date)
        .sum(:views)

      growth = if previous_period_views.zero?
        0
      else
        (((current_period_views - previous_period_views).to_f / previous_period_views) * 100).round(2)
      end

      {
        views_growth_percent: growth,
        current_period_views: current_period_views,
        previous_period_views: previous_period_views
      }
    end

    def top_performing_videos
      @user.videos
           .published
           .joins(:video_analytics)
           .where(video_analytics: { collected_at: @start_date..@end_date })
           .select("videos.*, MAX(video_analytics.engagement_rate) as max_engagement")
           .group("videos.id")
           .order("max_engagement DESC")
           .limit(5)
    end

    def recent_insights
      @user.insights.active.recent.limit(5)
    end
  end
end
