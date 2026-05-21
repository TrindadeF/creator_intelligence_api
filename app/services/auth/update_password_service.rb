module Auth
  class UpdatePasswordService
    def initialize(token:, password:, password_confirmation:)
      @token = token
      @password = password
      @password_confirmation = password_confirmation
    end

    def call
      user = User.find_by(reset_password_token: @token)

      return { success: false, error: "Invalid or expired token" } unless user&.password_reset_token_valid?

      if user.update(
        password: @password,
        password_confirmation: @password_confirmation,
        reset_password_token: nil,
        reset_password_sent_at: nil
      )
        user.invalidate_refresh_token!
        { success: true, user: user }
      else
        { success: false, errors: user.errors.full_messages }
      end
    end
  end
end
