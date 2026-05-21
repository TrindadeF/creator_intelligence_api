module Analytics
  class SyncSocialAccountJob < ApplicationJob
    queue_as :default

    def perform(social_account_id)
      social_account = SocialAccount.find(social_account_id)
      return unless social_account.active?

      Rails.logger.info("[SyncSocialAccountJob] Syncing #{social_account.provider} for user #{social_account.user_id}")

      case social_account.provider
      when "tiktok"
        TikTok::SyncAccountJob.perform_later(social_account.id)
      else
        Rails.logger.info("[SyncSocialAccountJob] No sync implementation yet for #{social_account.provider}")
      end
    end
  end
end
