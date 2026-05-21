module Analytics
  class BestPostingTimeAnalyzer
    def initialize(user:)
      @user = user
    end

    def call
      videos_with_analytics = load_data
      return { insights: [], stats: {} } if videos_with_analytics.empty?

      hourly_performance = calculate_hourly_performance(videos_with_analytics)
      daily_performance = calculate_daily_performance(videos_with_analytics)

      best_hour = hourly_performance.max_by { |_, v| v[:avg_engagement] }
      best_day = daily_performance.max_by { |_, v| v[:avg_engagement] }

      {
        stats: {
          hourly_performance: hourly_performance,
          daily_performance: daily_performance,
          best_hour: best_hour&.first,
          best_day: best_day&.first
        },
        insights: generate_insights(best_hour, best_day)
      }
    end

    private

    def load_data
      @user.videos
           .published
           .joins(:video_analytics)
           .where.not(published_at: nil)
           .select("videos.id, videos.published_at, video_analytics.engagement_rate, video_analytics.views")
    end

    def calculate_hourly_performance(data)
      grouped = data.group_by { |v| v.published_at.hour }
      grouped.transform_values do |videos|
        rates = videos.map(&:engagement_rate).compact
        {
          count: videos.size,
          avg_engagement: rates.empty? ? 0 : (rates.sum / rates.size).round(2),
          total_views: videos.sum { |v| v.views || 0 }
        }
      end
    end

    def calculate_daily_performance(data)
      day_names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
      grouped = data.group_by { |v| v.published_at.wday }
      grouped.transform_values do |videos|
        rates = videos.map(&:engagement_rate).compact
        {
          count: videos.size,
          avg_engagement: rates.empty? ? 0 : (rates.sum / rates.size).round(2)
        }
      end.transform_keys { |k| day_names[k] }
    end

    def generate_insights(best_hour, best_day)
      insights = []

      if best_hour
        hour = best_hour.first
        insights << {
          type: "best_posting_time",
          severity: "info",
          title: "Best posting time detected",
          description: "Your videos posted at #{hour}:00 get the highest engagement.",
          metadata: { best_hour: hour, performance: best_hour.last }
        }
      end

      if best_day
        insights << {
          type: "best_posting_time",
          severity: "info",
          title: "Best posting day detected",
          description: "#{best_day.first} is your best performing day for engagement.",
          metadata: { best_day: best_day.first, performance: best_day.last }
        }
      end

      insights
    end
  end
end
