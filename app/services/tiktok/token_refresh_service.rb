module TikTok
  # Refreshes an expired TikTok access token.
  # Should be called before any TikTok API request when token_expired? is true.
  class TokenRefreshService
    def initialize(social_account:)
      @account = social_account
    end

    def call
      unless @account.provider == "tiktok"
        return { success: false, error: "Not a TikTok account" }
      end

      if @account.refresh_token.blank?
        return { success: false, error: "No refresh token available. User must reconnect TikTok." }
      end

      response = TikTok::ApiClient.refresh_access_token(refresh_token: @account.refresh_token)
      body = response.body

      if response.success? && body["access_token"].present?
        update_tokens(body)
        { success: true, social_account: @account }
      else
        handle_refresh_failure(body)
      end
    rescue Faraday::Error => e
      { success: false, error: "Network error: #{e.message}" }
    end

    private

    def update_tokens(body)
      @account.update!(
        access_token:     body["access_token"],
        refresh_token:    body["refresh_token"] || @account.refresh_token,
        token_expires_at: body["expires_in"].to_i.seconds.from_now,
        active:           true
      )
    end

    def handle_refresh_failure(body)
      error_code = body["error"] || body["error_code"]
      error_msg  = body["error_description"] || body["message"] || "Token refresh failed"

      # Revoked/expired refresh token — force reconnect
      if error_code.to_s.include?("invalid") || error_code.to_s.include?("expired")
        @account.disconnect!
        return { success: false, error: "Refresh token revoked. Please reconnect TikTok.", reconnect_required: true }
      end

      { success: false, error: error_msg }
    end
  end
end
