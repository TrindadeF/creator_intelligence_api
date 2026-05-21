require "rails_helper"

RSpec.describe TikTok::OAuthService, type: :service do
  let(:user) { create(:user, :confirmed) }

  describe "#connect" do
    it "returns an authorization URL and state" do
      result = described_class.new(user: user).connect

      expect(result[:success]).to be true
      expect(result[:authorization_url]).to include("tiktok.com/v2/auth/authorize")
      expect(result[:state]).to be_present
    end

    it "stores state in Redis" do
      redis = instance_double(Redis)
      allow(Redis).to receive(:new).and_return(redis)
      allow(redis).to receive(:setex)

      result = described_class.new(user: user).connect

      expect(redis).to have_received(:setex).with(
        "tiktok:oauth:state:#{result[:state]}",
        TikTokConfig::STATE_TTL_SECONDS,
        user.id.to_s
      )
    end
  end

  describe ".handle_callback" do
    let(:valid_state) { "validstate123" }

    before do
      redis = instance_double(Redis)
      allow(Redis).to receive(:new).and_return(redis)
      allow(redis).to receive(:get).with("tiktok:oauth:state:#{valid_state}").and_return(user.id.to_s)
      allow(redis).to receive(:del)
    end

    context "when TikTok denies access" do
      it "returns failure with error message" do
        result = described_class.handle_callback(code: nil, state: valid_state, error: "access_denied")
        expect(result[:success]).to be false
        expect(result[:error]).to include("access_denied")
      end
    end

    context "with invalid state" do
      before do
        redis = instance_double(Redis)
        allow(Redis).to receive(:new).and_return(redis)
        allow(redis).to receive(:get).and_return(nil)
      end

      it "returns failure" do
        result = described_class.handle_callback(code: "somecode", state: "invalid_state")
        expect(result[:success]).to be false
        expect(result[:error]).to include("Invalid or expired state")
      end
    end

    context "with valid code and state" do
      let(:token_response_body) do
        {
          "access_token"       => "test_access_token",
          "refresh_token"      => "test_refresh_token",
          "open_id"            => "tiktok_user_123",
          "scope"              => "user.info.basic,video.list",
          "expires_in"         => 86400,
          "refresh_expires_in" => 31536000
        }
      end

      let(:profile_response_body) do
        {
          "data" => {
            "user" => {
              "display_name"   => "TestCreator",
              "avatar_url"     => "https://example.com/avatar.jpg",
              "follower_count" => 1000,
              "video_count"    => 50,
              "is_verified"    => false
            }
          }
        }
      end

      before do
        token_response = instance_double(Faraday::Response, success?: true, body: token_response_body)
        profile_response = instance_double(Faraday::Response, success?: true, body: profile_response_body)

        allow(TikTok::ApiClient).to receive(:exchange_code).and_return(token_response)
        allow_any_instance_of(TikTok::ApiClient).to receive(:fetch_user_info).and_return(profile_response)
      end

      it "creates a social account and returns success" do
        result = described_class.handle_callback(code: "valid_code", state: valid_state)

        expect(result[:success]).to be true
        expect(result[:social_account]).to be_a(SocialAccount)
        expect(result[:social_account].provider).to eq("tiktok")
        expect(result[:social_account].username).to eq("TestCreator")
        expect(result[:social_account].provider_account_id).to eq("tiktok_user_123")
      end

      it "updates existing account on reconnect" do
        create(:social_account, user: user, provider: "tiktok", provider_account_id: "old_id")

        result = described_class.handle_callback(code: "valid_code", state: valid_state)

        expect(result[:success]).to be true
        expect(user.social_accounts.tiktok.count).to eq(1)
        expect(result[:social_account].provider_account_id).to eq("tiktok_user_123")
      end
    end
  end
end
