module Ai
  # AI Insight Formatter - prepares analytical data for AI-powered text generation
  # NOTE: This service does NOT calculate metrics. Analytics engines handle calculations.
  # This service translates structured insights into natural language.
  #
  # Future integration: OpenAI GPT-4 API for generating human-readable summaries.
  class InsightFormatterService
    def initialize(insight_data:, user:)
      @insight_data = insight_data
      @user = user
    end

    def call
      formatted = format_for_ai(@insight_data)

      # TODO: Replace with actual OpenAI API call when ready
      # response = Ai::OpenaiClient.new.generate_summary(prompt: build_prompt(formatted))
      # { success: true, summary: response.content }

      # Fallback: rule-based text generation (no AI dependency)
      { success: true, summary: generate_fallback_summary(formatted) }
    end

    private

    def format_for_ai(data)
      {
        creator_name: @user.name,
        niche: @user.niche,
        insight_type: data[:insight_type],
        metrics: data[:metadata],
        title: data[:title],
        description: data[:description]
      }
    end

    def build_prompt(formatted_data)
      <<~PROMPT
        You are an analytics advisor for social media creators.
        Creator: #{formatted_data[:creator_name]}
        Niche: #{formatted_data[:niche] || "general"}

        Insight: #{formatted_data[:title]}
        Data: #{formatted_data[:metrics].to_json}

        Provide a concise, actionable summary in 2-3 sentences for the creator.
        Focus on what they should do next. Be specific and encouraging.
      PROMPT
    end

    def generate_fallback_summary(data)
      "#{data[:title]}: #{data[:description]}"
    end
  end
end
