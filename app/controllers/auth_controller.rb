class AuthController < ApplicationController
  skip_before_action :authenticate_request!, only: [:register, :login, :refresh, :forgot_password, :reset_password]

  def register
    result = Auth::RegisterService.new(register_params).call

    if result[:success]
      render json: {
        data: {
          user: UserSerializer.render_as_hash(result[:user]),
          token: result[:token],
          refresh_token: result[:refresh_token]
        }
      }, status: :created
    else
      render_error("Registration failed", status: :unprocessable_entity, errors: result[:errors])
    end
  end

  def login
    result = Auth::LoginService.new(
      email: params[:email],
      password: params[:password]
    ).call

    if result[:success]
      render json: {
        data: {
          user: UserSerializer.render_as_hash(result[:user]),
          token: result[:token],
          refresh_token: result[:refresh_token]
        }
      }
    else
      render_error(result[:error], status: :unauthorized)
    end
  end

  def refresh
    result = Auth::RefreshTokenService.new(
      refresh_token: params[:refresh_token]
    ).call

    if result[:success]
      render json: {
        data: {
          token: result[:token],
          refresh_token: result[:refresh_token]
        }
      }
    else
      render_error(result[:error], status: :unauthorized)
    end
  end

  def logout
    Auth::LogoutService.new(user: current_user).call
    render json: { message: "Logged out successfully" }
  end

  def forgot_password
    Auth::PasswordResetService.new(email: params[:email]).call
    render json: { message: "If that email exists, a reset link was sent." }
  end

  def reset_password
    result = Auth::UpdatePasswordService.new(
      token: params[:token],
      password: params[:password],
      password_confirmation: params[:password_confirmation]
    ).call

    if result[:success]
      render json: { message: "Password updated successfully" }
    else
      render_error(result[:error] || "Password update failed", errors: result[:errors])
    end
  end

  private

  def register_params
    params.permit(:name, :email, :password, :password_confirmation, :niche, :bio, :avatar_url)
  end
end
