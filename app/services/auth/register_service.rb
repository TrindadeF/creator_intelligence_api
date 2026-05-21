module Auth
  class RegisterService
    def initialize(params)
      @params = params
    end

    def call
      user = User.new(user_params)

      if user.save
        # TODO: Send confirmation email via job
        # Mailers::SendConfirmationEmailJob.perform_later(user.id)

        token = JwtService.encode({ user_id: user.id })
        refresh_token = user.generate_refresh_token!

        { success: true, user: user, token: token, refresh_token: refresh_token }
      else
        { success: false, errors: user.errors.full_messages }
      end
    end

    private

    def user_params
      @params.slice(:name, :email, :password, :password_confirmation, :niche, :bio, :avatar_url)
    end
  end
end
