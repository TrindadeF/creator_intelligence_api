module Analytics
  # Collects analytics for a single social account.
  # Dispatched by CollectAllAnalyticsJob for each active account.
  class CollectAccountAnalyticsJob < ApplicationJob
    queue_as :default

    sidekiq_options retry: 2

    def perform(social_account_id)
      account = SocialAccount.find(social_account_id)
      return unless account.active?

      result = Analytics::IngestionCoordinatorService.new(social_account: account).call

      if result[:success]
        Rails.logger.info(
          "[CollectAccountAnalyticsJob] account=#{social_account_id} " \
          "collected=#{result[:collected]} queued=#{result[:queued]}"
        )
      else
        Rails.logger.warn(
          "[CollectAccountAnalyticsJob] account=#{social_account_id} error=#{result[:error]}"
        )
      end
    end
  end
end
