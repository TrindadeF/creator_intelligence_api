module Analytics
  class SyncAllAccountsJob < ApplicationJob
    queue_as :low

    def perform
      SocialAccount.active.find_each do |account|
        SyncSocialAccountJob.perform_later(account.id)
      end

      Rails.logger.info("[SyncAllAccountsJob] Queued sync for #{SocialAccount.active.count} accounts")
    end
  end
end
