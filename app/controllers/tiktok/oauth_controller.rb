module TikTok
  class OAuthController < ApplicationController
    skip_before_action :authenticate_request!, only: [:callback]
    before_action :authenticate_request_optional!, only: [:callback]

    # GET /auth/tiktok/connect
    # Returns TikTok authorization URL. Frontend redirects the user to it.
    def connect
      result = TikTok::OAuthService.new(user: current_user).connect

      render json: {
        data: {
          authorization_url: result[:authorization_url],
          state:             result[:state]
        }
      }
    end

    # GET /auth/tiktok/callback
    # TikTok redirects here after user authorizes (or denies).
    # User identity is resolved from the OAuth state stored in Redis — no JWT needed.
    def callback
      result = TikTok::OAuthService.handle_callback(
        code:  params[:code],
        state: params[:state],
        error: params[:error]
      )

      if result[:success]
        account = result[:social_account]
        TikTok::SyncAccountJob.perform_later(account.id)

        redirect_to "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/social-accounts/tiktok/success?account_id=#{account.id}",
                    allow_other_host: true
      else
        error_message = CGI.escape(result[:error] || "Connection failed")
        redirect_to "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/social-accounts/tiktok/error?message=#{error_message}",
                    allow_other_host: true
      end
    end

    # POST /auth/tiktok/callback
    # Alternative flow: frontend handles TikTok redirect, then posts code+state here.
    def callback_json
      result = TikTok::OAuthService.handle_callback(
        code:  params[:code],
        state: params[:state],
        error: params[:error]
      )

      if result[:success]
        account = result[:social_account]
        TikTok::SyncAccountJob.perform_later(account.id)

        render json: { data: SocialAccountSerializer.render_as_hash(account) }, status: :created
      else
        render_error(result[:error] || "TikTok connection failed",
                     status: result[:reconnect_required] ? :unauthorized : :unprocessable_entity)
      end
    end

    # DELETE /auth/tiktok/disconnect
    def disconnect
      account = current_user.social_accounts.find_by(provider: "tiktok")
      return render_error("No TikTok account connected", status: :not_found) unless account

      TikTok::ApiClient.revoke_token(access_token: account.access_token) if account.access_token.present?
      account.disconnect!

      render json: { message: "TikTok account disconnected" }
    end
  end
end
