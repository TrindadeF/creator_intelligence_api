module TikTok
  # Fetches video statistics from TikTok API in batches of up to 20 video IDs.
  # Normalizes the raw TikTok response into the standard analytics_data hash
  # expected by Analytics::IngestVideoAnalyticsJob.
  #
  # Usage:
  #   results = TikTok::VideoStatsFetcher.new(social_account: account, video_ids: [...]).call
  #   results # => [{ external_video_id: "xxx", views: 1234, engagement_rate: 5.2, ... }, ...]
  class VideoStatsFetcher
    BATCH_SIZE = 20 # TikTok API limit per request

    def initialize(social_account:, video_ids:)
      @account   = social_account
      @video_ids = Array(video_ids)
    end

    def call
      return [] if @video_ids.empty?

      ensure_valid_token!
      client  = TikTok::ApiClient.new(access_token: @account.access_token)
      results = []

      @video_ids.each_slice(BATCH_SIZE) do |batch|
        batch_results = fetch_batch(client, batch)
        results.concat(batch_results)

        # Respect TikTok rate limits between batches
        sleep(0.3) if @video_ids.size > BATCH_SIZE
      end

      results
    rescue TikTok::TokenExpired => e
      Rails.logger.error("[TikTok::VideoStatsFetcher] #{e.message}")
      []
    rescue Faraday::Error => e
      Rails.logger.error("[TikTok::VideoStatsFetcher] Network error: #{e.message}")
      []
    end

    private

    def fetch_batch(client, video_ids)
      response = client.fetch_video_stats(video_ids: video_ids)
      body     = response.body

      unless response.success?
        log_api_error(body)
        return []
      end

      videos = body.dig("data", "videos") || []
      videos.map { |raw| normalize(raw) }.compact
    end

    # Normalize TikTok raw video data → standard analytics_data hash
    def normalize(raw)
      return nil if raw["id"].blank?

      views    = raw["view_count"].to_i
      likes    = raw["like_count"].to_i
      comments = raw["comment_count"].to_i
      shares   = raw["share_count"].to_i

      # avg_watch_time in seconds (TikTok may call it "average_time_watched")
      avg_watch = (raw["average_time_watched"] || raw["avg_watch_time"] || 0).to_f

      # total watch time in seconds
      total_watch = (raw["total_time_watched"] || raw["play_time"] || 0).to_i

      # completion / full-watch rate (0.0 – 100.0)
      completion = (raw["full_video_watched_rate"] || raw["completion_rate"] || 0).to_f
      completion = (completion * 100).round(2) if completion <= 1.0 # normalize 0–1 → 0–100

      # engagement rate = (likes + comments + shares) / views * 100
      engagement = if views.positive?
        (((likes + comments + shares).to_f / views) * 100).round(2)
      else
        0.0
      end

      {
        "external_video_id" => raw["id"],
        "views"             => views,
        "likes"             => likes,
        "comments"          => comments,
        "shares"            => shares,
        "saves"             => raw.fetch("bookmark_count", raw.fetch("save_count", 0)).to_i,
        "watch_time"        => total_watch,
        "avg_watch_time"    => avg_watch,
        "completion_rate"   => completion,
        "engagement_rate"   => engagement,
        "collected_at"      => Time.current.iso8601,
        "collection_source" => "tiktok_api",
        "raw_data"          => raw
      }
    end

    def ensure_valid_token!
      return unless @account.token_expired?

      result = TikTok::TokenRefreshService.new(social_account: @account).call
      raise TikTok::TokenExpired, result[:error] unless result[:success]

      @account.reload
    end

    def log_api_error(body)
      error  = body.dig("error", "message") || body["message"] || "Unknown error"
      code   = body.dig("error", "code") || body["error_code"]
      Rails.logger.error("[TikTok::VideoStatsFetcher] API error #{code}: #{error}")
    end
  end
end
