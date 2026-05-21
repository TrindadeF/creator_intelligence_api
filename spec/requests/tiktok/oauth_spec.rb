require "rails_helper"

RSpec.describe "TikTok OAuth", type: :request do
  let(:user) { create(:user, :confirmed) }

  describe "GET /auth/tiktok/connect" do
    it "returns authorization URL for authenticated user" do
      get "/auth/tiktok/connect", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"]["authorization_url"]).to include("tiktok.com/v2/auth/authorize")
      expect(json["data"]["state"]).to be_present
    end

    it "returns 401 without authentication" do
      get "/auth/tiktok/connect"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /auth/tiktok/callback" do
    let(:state) { "test_state_123" }

    context "when TikTok denies access" do
      it "redirects to frontend error page" do
        get "/auth/tiktok/callback", params: { error: "access_denied", state: state }
        expect(response).to have_http_status(:redirect)
        expect(response.location).to include("/social-accounts/tiktok/error")
      end
    end

    context "with invalid/expired state" do
      before do
        redis = instance_double(Redis)
        allow(Redis).to receive(:new).and_return(redis)
        allow(redis).to receive(:get).and_return(nil)
      end

      it "redirects to frontend error page" do
        get "/auth/tiktok/callback", params: { code: "somecode", state: "expired_state" }
        expect(response).to have_http_status(:redirect)
        expect(response.location).to include("/social-accounts/tiktok/error")
      end
    end
  end

  describe "DELETE /auth/tiktok/disconnect" do
    let!(:account) { create(:social_account, user: user, provider: "tiktok") }

    it "disconnects the account" do
      allow(TikTok::ApiClient).to receive(:revoke_token)

      delete "/auth/tiktok/disconnect", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(account.reload.active).to be false
    end

    it "returns 404 when no TikTok account" do
      account.destroy
      delete "/auth/tiktok/disconnect", headers: auth_headers_for(user)
      expect(response).to have_http_status(:not_found)
    end
  end
end
