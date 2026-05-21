module Analytics
  # Scheduled job — dispatches individual analytics collection jobs
  # for every active social account.
  #
  # Runs on a cron schedule (configured in config/sidekiq.yml).
  # Default: every 6 hours.
  class CollectAllAnalyticsJob < ApplicationJob
    queue_as :low

    def perform
      accounts = SocialAccount.active
      Rails.logger.info("[CollectAllAnalyticsJob] Dispatching analytics collection for #{accounts.count} accounts")

      accounts.find_each do |account|
        # Stagger jobs by 2s per account to avoid rate limit bursts
        delay = account.id % 60 * 2
        Analytics::CollectAccountAnalyticsJob.set(wait: delay.seconds).perform_later(account.id)
      end
    end
  end
end
