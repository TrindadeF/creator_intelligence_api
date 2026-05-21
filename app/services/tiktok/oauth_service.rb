module TikTok
  # Manages the full TikTok OAuth 2.0 flow.
  #
  # Flow:
  #   1. connect(user)    → generates state (Redis) + returns authorization URL
  #   2. callback(params) → validates state, exchanges code, upserts SocialAccount
  class OAuthService
    def initialize(user:)
      @user = user
    end

    # Step 1 — Returns { authorization_url:, state: }
    def connect
      state = generate_state
      store_state(state)

      {
        success: true,
        authorization_url: TikTok::ApiClient.authorization_url(state: state),
        state: state
      }
    end

    # Step 2 — Handles TikTok callback with code + state
    def self.handle_callback(code:, state:, error: nil)
      return { success: false, error: "TikTok denied access: #{error}" } if error.present?
      return { success: false, error: "Missing code or state" } if code.blank? || state.blank?

      user_id = validate_state(state)
      return { success: false, error: "Invalid or expired state. Please try again." } unless user_id

      user = User.find_by(id: user_id)
      return { success: false, error: "User not found" } unless user

      token_result = exchange_code(code)
      return token_result unless token_result[:success]

      account = upsert_social_account(user, token_result[:token_data])
      delete_state(state)

      { success: true, social_account: account }
    rescue TikTok::ApiError => e
      { success: false, error: e.message }
    end

    private

    def generate_state
      SecureRandom.urlsafe_base64(32)
    end

    def store_state(state)
      redis.setex(state_key(state), TikTokConfig::STATE_TTL_SECONDS, @user.id.to_s)
    end

    def self.validate_state(state)
      redis.get(state_key(state))
    end

    def self.delete_state(state)
      redis.del(state_key(state))
    end

    def self.exchange_code(code)
      response = TikTok::ApiClient.exchange_code(code: code)
      body = response.body

      if response.success? && body["access_token"].present?
        {
          success: true,
          token_data: {
            access_token:       body["access_token"],
            refresh_token:      body["refresh_token"],
            open_id:            body["open_id"],
            scope:              body["scope"],
            expires_in:         body["expires_in"].to_i,
            refresh_expires_in: body["refresh_expires_in"].to_i
          }
        }
      else
        error_msg = body.dig("error_description") || body.dig("message") || "Token exchange failed"
        raise TikTok::ApiError, error_msg
      end
    end

    def self.upsert_social_account(user, token_data)
      open_id = token_data[:open_id]
      raise TikTok::ApiError, "Missing open_id from TikTok" if open_id.blank?

      # Fetch profile to get display name
      profile = fetch_profile(token_data[:access_token])

      expires_at        = token_data[:expires_in].seconds.from_now
      refresh_expires_at = token_data[:refresh_expires_in].seconds.from_now

      account = user.social_accounts.find_or_initialize_by(provider: "tiktok")

      account.assign_attributes(
        provider_account_id:  open_id,
        username:             profile[:display_name],
        access_token:         token_data[:access_token],
        refresh_token:        token_data[:refresh_token],
        token_expires_at:     expires_at,
        connected_at:         Time.current,
        active:               true,
        metadata:             {
          scope:               token_data[:scope],
          refresh_expires_at:  refresh_expires_at.iso8601,
          avatar_url:          profile[:avatar_url],
          follower_count:      profile[:follower_count],
          video_count:         profile[:video_count],
          is_verified:         profile[:is_verified]
        }
      )

      account.save!
      account
    end

    def self.fetch_profile(access_token)
      client = TikTok::ApiClient.new(access_token: access_token)
      response = client.fetch_user_info
      user_data = response.body.dig("data", "user") || {}

      {
        display_name:   user_data["display_name"],
        avatar_url:     user_data["avatar_url"],
        follower_count: user_data["follower_count"],
        video_count:    user_data["video_count"],
        is_verified:    user_data["is_verified"]
      }
    rescue => e
      Rails.logger.warn("[TikTok::OAuthService] Profile fetch failed: #{e.message}")
      {}
    end

    def redis
      @redis ||= Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
    end

    def self.redis
      @redis ||= Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
    end

    def state_key(state)
      self.class.state_key(state)
    end

    def self.state_key(state)
      "tiktok:oauth:state:#{state}"
    end
  end
end
