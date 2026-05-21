module Insights
  class GeneratorService
    def initialize(user:)
      @user = user
    end

    def call
      insights = []

      insights += analyze_retention
      insights += analyze_posting_time
      insights += analyze_format_performance

      persist_insights(insights)

      { success: true, insights_created: insights.size }
    end

    private

    def analyze_retention
      result = Analytics::RetentionAnalyzer.new(
        videos: @user.videos.published,
        user: @user
      ).call

      result[:insights] || []
    end

    def analyze_posting_time
      result = Analytics::BestPostingTimeAnalyzer.new(user: @user).call
      result[:insights] || []
    end

    def analyze_format_performance
      result = Analytics::FormatPerformanceAnalyzer.new(user: @user).call
      result[:insights] || []
    end

    def persist_insights(insights_data)
      insights_data.each do |data|
        next if recent_duplicate?(data[:type])

        @user.insights.create!(
          insight_type: data[:type],
          title: data[:title],
          description: data[:description],
          severity: data[:severity] || "info",
          metadata: data[:metadata] || {},
          generated_by: "system"
        )

        # Format AI summary asynchronously
        # Ai::FormatInsightJob.perform_later(insight.id)
      end
    end

    def recent_duplicate?(type)
      @user.insights
           .where(insight_type: type, generated_by: "system")
           .where("created_at > ?", 24.hours.ago)
           .exists?
    end
  end
end
