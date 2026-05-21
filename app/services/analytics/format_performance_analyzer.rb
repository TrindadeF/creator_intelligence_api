module Analytics
  class FormatPerformanceAnalyzer
    SHORT_VIDEO_MAX = 30
    MEDIUM_VIDEO_MAX = 60

    def initialize(user:)
      @user = user
    end

    def call
      data = load_data
      return { insights: [], stats: {} } if data.empty?

      stats = analyze_by_duration(data)
      {
        stats: stats,
        insights: generate_insights(stats)
      }
    end

    private

    def load_data
      @user.videos
           .published
           .joins(:video_analytics)
           .where.not(duration_seconds: nil)
           .select("videos.id, videos.duration_seconds, video_analytics.engagement_rate, video_analytics.completion_rate, video_analytics.views")
    end

    def analyze_by_duration(data)
      groups = {
        short: data.select { |v| v.duration_seconds <= SHORT_VIDEO_MAX },
        medium: data.select { |v| v.duration_seconds > SHORT_VIDEO_MAX && v.duration_seconds <= MEDIUM_VIDEO_MAX },
        long: data.select { |v| v.duration_seconds > MEDIUM_VIDEO_MAX }
      }

      groups.transform_values do |videos|
        next({ count: 0, avg_engagement_rate: 0, avg_completion_rate: 0, total_views: 0 }) if videos.empty?

        rates = videos.map(&:engagement_rate).compact
        completions = videos.map(&:completion_rate).compact

        {
          count: videos.size,
          avg_engagement_rate: rates.empty? ? 0 : (rates.sum / rates.size).round(2),
          avg_completion_rate: completions.empty? ? 0 : (completions.sum / completions.size).round(2),
          total_views: videos.sum { |v| v.views || 0 }
        }
      end
    end

    def generate_insights(stats)
      insights = []
      best_format = stats.max_by { |_, v| v[:avg_engagement_rate] || 0 }

      return insights unless best_format

      format_labels = { short: "short (≤30s)", medium: "medium (31-60s)", long: "long (>60s)" }
      format_name = format_labels[best_format.first] || best_format.first.to_s

      insights << {
        type: "format_performance",
        severity: "success",
        title: "Best format identified",
        description: "#{format_name.capitalize} videos perform best with #{best_format.last[:avg_engagement_rate]}% average engagement.",
        metadata: { best_format: best_format.first, stats: stats }
      }

      if stats[:long][:count] > 0 &&
         stats[:long][:avg_engagement_rate] < (stats[:short][:avg_engagement_rate] * 0.7)
        insights << {
          type: "long_video_underperform",
          severity: "warning",
          title: "Long videos underperforming",
          description: "Your long videos get #{stats[:long][:avg_engagement_rate]}% engagement vs #{stats[:short][:avg_engagement_rate]}% for short videos.",
          metadata: stats
        }
      end

      insights
    end
  end
end
