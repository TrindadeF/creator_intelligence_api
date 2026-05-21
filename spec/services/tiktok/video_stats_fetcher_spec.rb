require "rails_helper"

RSpec.describe TikTok::VideoStatsFetcher do
  let(:social_account) { create(:social_account, provider: :tiktok, access_token: "tok") }
  let(:video_ids)      { %w[vid1 vid2] }

  subject { described_class.new(social_account: social_account, video_ids: video_ids) }

  let(:raw_video) do
    {
      "id"                       => "vid1",
      "view_count"               => 1000,
      "like_count"               => 50,
      "comment_count"            => 10,
      "share_count"              => 5,
      "average_time_watched"     => 30.5,
      "total_time_watched"       => 30500,
      "full_video_watched_rate"  => 0.25,
      "bookmark_count"           => 8
    }
  end

  let(:api_response) do
    instance_double(Faraday::Response,
      success?: true,
      body: { "data" => { "videos" => [raw_video] } }
    )
  end

  let(:api_client) { instance_double(TikTok::ApiClient, fetch_video_stats: api_response) }

  before do
    allow(TikTok::ApiClient).to receive(:new).and_return(api_client)
    allow(social_account).to receive(:token_expired?).and_return(false)
  end

  describe "#call" do
    it "returns normalized stats for each video" do
      results = subject.call

      expect(results.size).to eq(1)
      stat = results.first

      expect(stat["external_video_id"]).to eq("vid1")
      expect(stat["views"]).to eq(1000)
      expect(stat["likes"]).to eq(50)
      expect(stat["comments"]).to eq(10)
      expect(stat["shares"]).to eq(5)
      expect(stat["saves"]).to eq(8)
      expect(stat["avg_watch_time"]).to eq(30.5)
      expect(stat["completion_rate"]).to eq(25.0)
      # engagement = (50+10+5)/1000 * 100 = 6.5
      expect(stat["engagement_rate"]).to eq(6.5)
      expect(stat["collected_at"]).to be_present
    end

    it "returns empty array when video_ids is empty" do
      fetcher = described_class.new(social_account: social_account, video_ids: [])
      expect(fetcher.call).to eq([])
    end

    it "refreshes token when expired" do
      allow(social_account).to receive(:token_expired?).and_return(true)
      refresh_service = instance_double(TikTok::TokenRefreshService, call: { success: true })
      allow(TikTok::TokenRefreshService).to receive(:new).and_return(refresh_service)
      allow(social_account).to receive(:reload)

      subject.call
      expect(TikTok::TokenRefreshService).to have_received(:new)
    end

    it "returns empty array on API error" do
      error_response = instance_double(Faraday::Response,
        success?: false,
        body: { "error" => { "code" => 401, "message" => "Unauthorized" } }
      )
      allow(api_client).to receive(:fetch_video_stats).and_return(error_response)

      expect(subject.call).to eq([])
    end

    it "returns empty array on expired token that cannot be refreshed" do
      allow(social_account).to receive(:token_expired?).and_return(true)
      failed_refresh = instance_double(TikTok::TokenRefreshService, call: { success: false, error: "revoked" })
      allow(TikTok::TokenRefreshService).to receive(:new).and_return(failed_refresh)

      expect(subject.call).to eq([])
    end
  end
end
