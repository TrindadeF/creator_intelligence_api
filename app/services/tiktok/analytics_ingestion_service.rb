module TikTok
  # Orchestrates a full analytics collection run for a TikTok SocialAccount.
  #
  # What it does:
  #   1. Loads all known video external IDs from the DB for this account
  #   2. Fetches current stats from TikTok API (batched via VideoStatsFetcher)
  #   3. Enqueues Analytics::IngestVideoAnalyticsJob for each video
  #   4. Logs a collection summary and timestamps the account
  #
  # Each call creates a new historical snapshot — previous records are never overwritten.
  class AnalyticsIngestionService
    def initialize(social_account:)
      @account = social_account
      @user    = social_account.user
    end

    def call
      unless @account.active? && @account.provider == "tiktok"
        return { success: false, error: "Account is not an active TikTok account" }
      end

      video_ids = load_video_external_ids
      if video_ids.empty?
        Rails.logger.info("[TikTok::AnalyticsIngestionService] No videos found for account #{@account.id}")
        return { success: true, collected: 0, queued: 0 }
      end

      Rails.logger.info("[TikTok::AnalyticsIngestionService] Collecting analytics for #{video_ids.size} videos (account #{@account.id})")

      stats_list = TikTok::VideoStatsFetcher.new(
        social_account: @account,
        video_ids:      video_ids
      ).call

      queued = enqueue_ingestion_jobs(stats_list)
      stamp_collection_time

      Rails.logger.info("[TikTok::AnalyticsIngestionService] Queued #{queued}/#{video_ids.size} analytics jobs for account #{@account.id}")

      { success: true, collected: stats_list.size, queued: queued }
    rescue => e
      Rails.logger.error("[TikTok::AnalyticsIngestionService] Error: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
      { success: false, error: e.message }
    end

    private

    def load_video_external_ids
      @account.videos.published.pluck(:external_video_id)
    end

    def enqueue_ingestion_jobs(stats_list)
      # Build a lookup: external_video_id → internal video_id
      external_ids = stats_list.map { |s| s["external_video_id"] }
      video_lookup = Video
        .where(social_account: @account, external_video_id: external_ids)
        .pluck(:external_video_id, :id)
        .to_h

      queued = 0
      stats_list.each do |stats|
        video_id = video_lookup[stats["external_video_id"]]
        next unless video_id

        Analytics::IngestVideoAnalyticsJob.perform_later(video_id, stats)
        queued += 1
      end

      queued
    end

    def stamp_collection_time
      @account.update!(
        metadata: @account.metadata.merge(
          "analytics_last_collected_at" => Time.current.iso8601
        )
      )
    end
  end
end
