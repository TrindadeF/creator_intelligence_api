module Analytics
  class EngagementCalculator
    def initialize(analytics_records)
      @analytics = Array(analytics_records)
    end

    def call
      return {} if @analytics.empty?

      {
        avg_engagement_rate: calculate_avg_engagement_rate,
        avg_views: calculate_avg_views,
        total_likes: total(:likes),
        total_comments: total(:comments),
        total_shares: total(:shares),
        total_saves: total(:saves),
        total_views: total(:views),
        best_performing: best_performing_metric
      }
    end

    private

    def calculate_avg_engagement_rate
      rates = @analytics.map(&:engagement_rate).compact
      return 0.0 if rates.empty?
      (rates.sum / rates.size).round(2)
    end

    def calculate_avg_views
      views = @analytics.map(&:views).compact
      return 0 if views.empty?
      (views.sum / views.size).round
    end

    def total(field)
      @analytics.sum { |a| a.public_send(field) || 0 }
    end

    def best_performing_metric
      sorted = @analytics.sort_by { |a| -(a.engagement_rate || 0) }
      metric = sorted.first
      return unless metric

      {
        video_id: metric.video_id,
        engagement_rate: metric.engagement_rate,
        views: metric.views,
        collected_at: metric.collected_at
      }
    end
  end
end
