module Auth
  class RefreshTokenService
    def initialize(refresh_token:)
      @refresh_token = refresh_token
    end

    def call
      return { success: false, error: "Refresh token not provided" } if @refresh_token.blank?

      user = User.find_by(refresh_token: @refresh_token)

      unless user&.refresh_token_valid?
        return { success: false, error: "Invalid or expired refresh token" }
      end

      new_token = Auth::JwtService.encode({ user_id: user.id })
      new_refresh_token = user.generate_refresh_token!

      { success: true, user: user, token: new_token, refresh_token: new_refresh_token }
    end
  end
end
