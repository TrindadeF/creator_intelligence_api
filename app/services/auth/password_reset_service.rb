module Auth
  class PasswordResetService
    def initialize(email:)
      @email = email&.downcase&.strip
    end

    def call
      user = User.find_by(email: @email)
      return { success: true } unless user

      user.generate_password_reset_token!
      # TODO: Mailers::SendPasswordResetJob.perform_later(user.id)

      { success: true }
    end
  end
end
