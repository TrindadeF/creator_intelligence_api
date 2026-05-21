class SocialAccountsController < ApplicationController
  before_action :set_social_account, only: [:destroy]

  def index
    accounts = current_user.social_accounts.active
    render json: { data: SocialAccountSerializer.render_as_hash(accounts) }
  end

  def create
    account = current_user.social_accounts.build(social_account_params)
    account.connected_at = Time.current

    if account.save
      render json: { data: SocialAccountSerializer.render_as_hash(account) }, status: :created
    else
      render_error("Failed to connect account", errors: account.errors.full_messages)
    end
  end

  def destroy
    @social_account.disconnect!
    render json: { message: "Account disconnected" }
  end

  private

  def set_social_account
    @social_account = current_user.social_accounts.find(params[:id])
  end

  def social_account_params
    params.permit(:provider, :provider_account_id, :username, :access_token, :refresh_token, :metadata)
  end
end
