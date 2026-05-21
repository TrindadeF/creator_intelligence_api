module Ai
  # Placeholder for OpenAI integration
  # Replace with actual implementation when ready to integrate AI
  class OpenaiClient
    def initialize
      @api_key = ENV["OPENAI_API_KEY"]
      @model = ENV.fetch("OPENAI_MODEL", "gpt-4o-mini")
    end

    def generate_summary(prompt:, max_tokens: 200)
      raise NotImplementedError, "OpenAI integration not yet configured. Set OPENAI_API_KEY to enable."

      # Future implementation:
      # connection = Faraday.new("https://api.openai.com") do |f|
      #   f.request :json
      #   f.response :json
      # end
      # response = connection.post("/v1/chat/completions", {
      #   model: @model,
      #   messages: [{ role: "user", content: prompt }],
      #   max_tokens: max_tokens
      # }, { "Authorization" => "Bearer #{@api_key}" })
      # OpenStruct.new(content: response.body.dig("choices", 0, "message", "content"))
    end
  end
end
