module Mailers
  class SendConfirmationEmailJob < ApplicationJob
    queue_as :mailers

    def perform(user_id)
      user = User.find_by(id: user_id)
      return unless user
      return if user.confirmed?

      UserMailer.confirmation_email(user).deliver_now
    end
  end
end
