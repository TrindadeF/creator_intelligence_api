module Analytics
  class RetentionAnalyzer
    POOR_RETENTION_THRESHOLD = 30.0
    GOOD_RETENTION_THRESHOLD = 60.0

    def initialize(videos:, user:)
      @videos = videos
      @user = user
    end

    def call
      return { insights: [], stats: {} } if @videos.empty?

      stats = calculate_stats
      insights = generate_insights(stats)

      { stats: stats, insights: insights }
    end

    private

    def calculate_stats
      analytics = VideoAnalytic.where(video: @videos)
                               .where("retention_rate > 0")
                               .select(:video_id, :retention_rate, :avg_watch_time, :completion_rate)

      return {} if analytics.empty?

      rates = analytics.map(&:retention_rate)
      {
        avg_retention_rate: (rates.sum / rates.size).round(2),
        min_retention_rate: rates.min.round(2),
        max_retention_rate: rates.max.round(2),
        poor_retention_count: rates.count { |r| r < POOR_RETENTION_THRESHOLD },
        good_retention_count: rates.count { |r| r >= GOOD_RETENTION_THRESHOLD }
      }
    end

    def generate_insights(stats)
      return [] if stats.empty?

      insights = []

      if stats[:avg_retention_rate] < POOR_RETENTION_THRESHOLD
        insights << {
          type: "retention_drop",
          severity: "warning",
          title: "Low average retention rate",
          description: "Your average retention rate is #{stats[:avg_retention_rate]}%. Consider improving your hooks and content pacing.",
          metadata: stats
        }
      end

      insights
    end
  end
end
