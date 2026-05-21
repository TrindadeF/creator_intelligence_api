require "rails_helper"

RSpec.describe TikTok::TokenRefreshService, type: :service do
  let(:user)    { create(:user, :confirmed) }
  let(:account) { create(:social_account, user: user, provider: "tiktok", refresh_token: "valid_refresh") }

  describe "#call" do
    context "when refresh succeeds" do
      let(:success_body) do
        {
          "access_token"  => "new_access_token",
          "refresh_token" => "new_refresh_token",
          "expires_in"    => 86400
        }
      end

      before do
        response = instance_double(Faraday::Response, success?: true, body: success_body)
        allow(TikTok::ApiClient).to receive(:refresh_access_token).and_return(response)
      end

      it "updates tokens and returns success" do
        result = described_class.new(social_account: account).call

        expect(result[:success]).to be true
        expect(account.reload.access_token).to eq("new_access_token")
        expect(account.reload.refresh_token).to eq("new_refresh_token")
      end
    end

    context "when refresh token is expired/revoked" do
      let(:failure_body) { { "error" => "invalid_grant", "error_description" => "Refresh token expired" } }

      before do
        response = instance_double(Faraday::Response, success?: false, body: failure_body)
        allow(TikTok::ApiClient).to receive(:refresh_access_token).and_return(response)
      end

      it "disconnects the account and requires reconnect" do
        result = described_class.new(social_account: account).call

        expect(result[:success]).to be false
        expect(result[:reconnect_required]).to be true
        expect(account.reload.active).to be false
      end
    end

    context "for a non-TikTok account" do
      let(:youtube_account) { build(:social_account, provider: "youtube") }

      it "returns failure" do
        result = described_class.new(social_account: youtube_account).call
        expect(result[:success]).to be false
      end
    end
  end
end
