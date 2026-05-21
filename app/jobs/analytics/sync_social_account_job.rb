module Analytics
  class SyncSocialAccountJob < ApplicationJob
    queue_as :default

    def perform(social_account_id)
      social_account = SocialAccount.find(social_account_id)
      return unless social_account.active?

      Rails.logger.info("[SyncSocialAccountJob] Syncing #{social_account.provider} for user #{social_account.user_id}")

      # TODO: Implement provider-specific sync
      # case social_account.provider
      # when "tiktok"
      #   TikTok::SyncAccountService.new(social_account).call
      # when "youtube"
      #   Youtube::SyncAccountService.new(social_account).call
      # end
    end
  end
end
