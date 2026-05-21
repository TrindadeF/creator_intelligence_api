class UserMailer < ApplicationMailer
  default from: ENV.fetch("MAILER_FROM", "Creator IQ <noreply@creatoriq.app>")

  # Sent after registration — includes a confirmation link
  def confirmation_email(user)
    @user              = user
    @confirmation_url  = "#{frontend_url}/confirm-email?token=#{user.confirmation_token}"
    mail(to: @user.email, subject: "Confirm your Creator IQ account")
  end

  # Sent on forgot_password — includes a reset link
  def password_reset_email(user)
    @user       = user
    @reset_url  = "#{frontend_url}/reset-password?token=#{user.reset_password_token}"
    mail(to: @user.email, subject: "Reset your Creator IQ password")
  end

  private

  def frontend_url
    ENV.fetch("FRONTEND_URL", "http://localhost:3001")
  end
end
