module Auth
  class LogoutService
    def initialize(user:)
      @user = user
    end

    def call
      @user.invalidate_refresh_token!
      { success: true }
    end
  end
end
