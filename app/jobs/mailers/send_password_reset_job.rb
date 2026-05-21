module Mailers
  class SendPasswordResetJob < ApplicationJob
    queue_as :mailers

    def perform(user_id)
      user = User.find_by(id: user_id)
      return unless user
      return unless user.password_reset_token_valid?

      UserMailer.password_reset_email(user).deliver_now
    end
  end
end
