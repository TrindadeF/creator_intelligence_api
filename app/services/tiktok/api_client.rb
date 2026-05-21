module TikTok
  class ApiClient
    BASE_URL = "https://open.tiktokapis.com".freeze
    AUTH_BASE_URL = "https://www.tiktok.com".freeze

    USER_INFO_FIELDS = %w[
      open_id union_id avatar_url avatar_url_100 display_name
      bio_description profile_deep_link is_verified
      follower_count following_count likes_count video_count
    ].join(",").freeze

    VIDEO_LIST_FIELDS = %w[
      id title video_description duration cover_image_url
      embed_link share_url create_time
      like_count comment_count share_count view_count
    ].join(",").freeze

    # Extended fields for analytics collection (requires video.list scope)
    VIDEO_ANALYTICS_FIELDS = %w[
      id
      view_count
      like_count
      comment_count
      share_count
      average_time_watched
      total_time_watched
      reach
      full_video_watched_rate
    ].join(",").freeze

    def initialize(access_token: nil)
      @access_token = access_token
    end

    # ── OAuth ─────────────────────────────────────────────────────────────────

    def self.authorization_url(state:, scope: default_scope)
      params = {
        client_key:    TikTokConfig::CLIENT_KEY,
        response_type: "code",
        scope:         scope,
        redirect_uri:  TikTokConfig::REDIRECT_URI,
        state:         state
      }
      "#{AUTH_BASE_URL}/v2/auth/authorize/?#{params.to_query}"
    end

    def self.exchange_code(code:)
      connection(AUTH_BASE_URL).post("/v2/oauth/token/") do |req|
        req.headers["Content-Type"] = "application/x-www-form-urlencoded"
        req.body = URI.encode_www_form(
          client_key:    TikTokConfig::CLIENT_KEY,
          client_secret: TikTokConfig::CLIENT_SECRET,
          code:          code,
          grant_type:    "authorization_code",
          redirect_uri:  TikTokConfig::REDIRECT_URI
        )
      end
    end

    def self.refresh_access_token(refresh_token:)
      connection(AUTH_BASE_URL).post("/v2/oauth/token/") do |req|
        req.headers["Content-Type"] = "application/x-www-form-urlencoded"
        req.body = URI.encode_www_form(
          client_key:    TikTokConfig::CLIENT_KEY,
          client_secret: TikTokConfig::CLIENT_SECRET,
          grant_type:    "refresh_token",
          refresh_token: refresh_token
        )
      end
    end

    def self.revoke_token(access_token:)
      connection(BASE_URL).post("/v2/oauth/revoke/") do |req|
        req.headers["Content-Type"] = "application/x-www-form-urlencoded"
        req.body = URI.encode_www_form(
          client_key:   TikTokConfig::CLIENT_KEY,
          token:        access_token
        )
      end
    end

    # ── User ──────────────────────────────────────────────────────────────────

    def fetch_user_info
      authenticated_connection.get("/v2/user/info/") do |req|
        req.params["fields"] = USER_INFO_FIELDS
      end
    end

    # ── Videos ────────────────────────────────────────────────────────────────

    def fetch_video_list(cursor: nil, max_count: 20)
      authenticated_connection.post("/v2/video/list/") do |req|
        req.headers["Content-Type"] = "application/json"
        req.params["fields"] = VIDEO_LIST_FIELDS
        body = { max_count: max_count }
        body[:cursor] = cursor if cursor
        req.body = body.to_json
      end
    end

    def fetch_video_query(video_ids:)
      authenticated_connection.post("/v2/video/query/") do |req|
        req.headers["Content-Type"] = "application/json"
        req.params["fields"] = VIDEO_LIST_FIELDS
        req.body = { filters: { video_ids: Array(video_ids) } }.to_json
      end
    end

    # Fetches analytics-focused stats for specific video IDs.
    # Uses extended fields (watch time, reach, completion rate).
    def fetch_video_stats(video_ids:)
      authenticated_connection.post("/v2/video/query/") do |req|
        req.headers["Content-Type"] = "application/json"
        req.params["fields"] = VIDEO_ANALYTICS_FIELDS
        req.body = { filters: { video_ids: Array(video_ids) } }.to_json
      end
    end

    private

    def authenticated_connection
      raise TikTok::AuthError, "Access token required" if @access_token.blank?

      self.class.connection(BASE_URL, @access_token)
    end

    def self.connection(base_url, token = nil)
      Faraday.new(url: base_url) do |f|
        f.request  :json
        f.response :json
        f.request  :retry, max: 2, interval: 0.5, retry_statuses: [429, 500, 502, 503]
        f.adapter  Faraday.default_adapter
        f.headers["Authorization"] = "Bearer #{token}" if token
      end
    end

    def self.default_scope
      TikTokConfig::SCOPES.join(",")
    end
  end
end
