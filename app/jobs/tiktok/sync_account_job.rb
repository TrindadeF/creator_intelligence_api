module TikTok
  # Runs a full sync for a TikTok social account:
  # 1. Refreshes profile metadata
  # 2. Syncs videos + seeds initial analytics
  class SyncAccountJob < ApplicationJob
    queue_as :default

    sidekiq_options retry: 3, dead: false

    def perform(social_account_id)
      account = SocialAccount.find(social_account_id)

      return unless account.active? && account.provider == "tiktok"

      Rails.logger.info("[TikTok::SyncAccountJob] Starting sync for account #{account.id}")

      # 1. Refresh profile
      profile_result = TikTok::UserProfileService.new(social_account: account).call
      unless profile_result[:success]
        Rails.logger.warn("[TikTok::SyncAccountJob] Profile sync failed: #{profile_result[:error]}")
        return if profile_result[:reconnect_required]
      end

      # 2. Sync videos
      video_result = TikTok::VideoSyncService.new(social_account: account).call
      unless video_result[:success]
        Rails.logger.warn("[TikTok::SyncAccountJob] Video sync failed: #{video_result[:error]}")
      end

      # 3. Collect analytics for all videos
      analytics_result = TikTok::AnalyticsIngestionService.new(social_account: account).call
      unless analytics_result[:success]
        Rails.logger.warn("[TikTok::SyncAccountJob] Analytics ingestion failed: #{analytics_result[:error]}")
      end

      # 4. Generate insights after sync + analytics collection
      Insights::GenerateInsightsJob.perform_later(account.user_id)

      Rails.logger.info("[TikTok::SyncAccountJob] Completed for account #{account.id}. Videos synced: #{video_result[:synced_count]}")
    end
  end
end
