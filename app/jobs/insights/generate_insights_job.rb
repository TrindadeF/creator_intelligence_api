module Insights
  class GenerateInsightsJob < ApplicationJob
    queue_as :low

    def perform(user_id)
      user = User.find(user_id)
      result = Insights::GeneratorService.new(user: user).call
      Rails.logger.info("[GenerateInsightsJob] Generated #{result[:insights_created]} insights for user #{user_id}")
    end
  end
end
