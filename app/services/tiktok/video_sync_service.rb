module TikTok
  # Syncs TikTok videos for a given SocialAccount.
  # Paginates through the video list and upserts Video records.
  class VideoSyncService
    MAX_PER_PAGE = 20

    def initialize(social_account:)
      @account = social_account
      @user    = social_account.user
    end

    def call
      ensure_valid_token!

      synced_count = 0
      cursor       = nil

      loop do
        result = fetch_page(cursor)
        break unless result[:success]

        videos    = result[:videos]
        cursor    = result[:cursor]
        has_more  = result[:has_more]

        videos.each { |v| upsert_video(v) }
        synced_count += videos.size

        break unless has_more && cursor
      end

      Rails.logger.info("[TikTok::VideoSyncService] Synced #{synced_count} videos for account #{@account.id}")
      { success: true, synced_count: synced_count }
    rescue TikTok::TokenExpired
      { success: false, error: "Token expired", reconnect_required: true }
    rescue Faraday::Error => e
      { success: false, error: "Network error: #{e.message}" }
    end

    private

    def ensure_valid_token!
      return unless @account.token_expired?

      result = TikTok::TokenRefreshService.new(social_account: @account).call
      raise TikTok::TokenExpired unless result[:success]

      @account.reload
    end

    def fetch_page(cursor)
      client   = TikTok::ApiClient.new(access_token: @account.access_token)
      response = client.fetch_video_list(cursor: cursor, max_count: MAX_PER_PAGE)
      body     = response.body

      unless response.success?
        Rails.logger.error("[TikTok::VideoSyncService] API error: #{body}")
        return { success: false }
      end

      data = body.dig("data") || {}
      {
        success:  true,
        videos:   data["videos"] || [],
        cursor:   data["cursor"],
        has_more: data["has_more"] || false
      }
    end

    def upsert_video(video_data)
      video = @account.videos.find_or_initialize_by(
        external_video_id: video_data["id"]
      )

      video.assign_attributes(
        user:             @user,
        title:            video_data["title"],
        description:      video_data["video_description"],
        duration_seconds: video_data["duration"],
        thumbnail_url:    video_data["cover_image_url"],
        video_url:        video_data["share_url"],
        published_at:     video_data["create_time"] ? Time.at(video_data["create_time"]) : nil,
        status:           "published",
        metadata:         {
          embed_link:    video_data["embed_link"],
          like_count:    video_data["like_count"],
          comment_count: video_data["comment_count"],
          share_count:   video_data["share_count"],
          view_count:    video_data["view_count"]
        }
      )

      if video.save
        # Seed initial analytics snapshot from video list data
        seed_initial_analytics(video, video_data) if video.previously_new_record?
      else
        Rails.logger.warn("[TikTok::VideoSyncService] Failed to save video #{video_data['id']}: #{video.errors.full_messages}")
      end
    end

    def seed_initial_analytics(video, data)
      views = data["view_count"].to_i
      likes = data["like_count"].to_i
      comments = data["comment_count"].to_i
      shares = data["share_count"].to_i

      engagement = views.positive? ? (((likes + comments + shares).to_f / views) * 100).round(2) : 0.0

      VideoAnalytic.create!(
        video:           video,
        views:           views,
        likes:           likes,
        comments:        comments,
        shares:          shares,
        engagement_rate: engagement,
        collected_at:    Time.current,
        collection_source: "tiktok_sync"
      )
    rescue => e
      Rails.logger.warn("[TikTok::VideoSyncService] Analytics seed failed for video #{video.id}: #{e.message}")
    end
  end
end
