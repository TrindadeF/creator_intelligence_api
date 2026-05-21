module Auth
  class LoginService
    def initialize(email:, password:)
      @email = email&.downcase&.strip
      @password = password
    end

    def call
      user = User.find_by(email: @email)

      unless user&.authenticate(@password)
        return { success: false, error: "Invalid email or password" }
      end

      unless user.active?
        return { success: false, error: "Account is deactivated" }
      end

      token = Auth::JwtService.encode({ user_id: user.id })
      refresh_token = user.generate_refresh_token!

      { success: true, user: user, token: token, refresh_token: refresh_token }
    end
  end
end
