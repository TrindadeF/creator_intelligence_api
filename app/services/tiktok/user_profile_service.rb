module TikTok
  # Fetches the latest TikTok profile data and updates the SocialAccount metadata.
  class UserProfileService
    def initialize(social_account:)
      @account = social_account
    end

    def call
      ensure_valid_token!

      client   = TikTok::ApiClient.new(access_token: @account.access_token)
      response = client.fetch_user_info
      body     = response.body

      unless response.success?
        return { success: false, error: body.dig("error", "message") || "Failed to fetch profile" }
      end

      user_data = body.dig("data", "user") || {}
      update_account(user_data)

      { success: true, profile: user_data }
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

    def update_account(user_data)
      @account.update!(
        username: user_data["display_name"] || @account.username,
        metadata: @account.metadata.merge(
          avatar_url:     user_data["avatar_url"],
          follower_count: user_data["follower_count"],
          following_count: user_data["following_count"],
          likes_count:    user_data["likes_count"],
          video_count:    user_data["video_count"],
          is_verified:    user_data["is_verified"],
          last_synced_at: Time.current.iso8601
        )
      )
    end
  end
end
