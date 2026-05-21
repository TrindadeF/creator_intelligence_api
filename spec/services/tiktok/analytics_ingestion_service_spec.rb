require "rails_helper"

RSpec.describe TikTok::AnalyticsIngestionService do
  let(:user)           { create(:user) }
  let(:social_account) { create(:social_account, user: user, provider: :tiktok) }
  let(:video)          { create(:video, user: user, social_account: social_account) }

  subject { described_class.new(social_account: social_account) }

  let(:stats) do
    [{
      "external_video_id" => video.external_video_id,
      "views"             => 500,
      "likes"             => 25,
      "comments"          => 5,
      "shares"            => 2,
      "saves"             => 3,
      "watch_time"        => 5000,
      "avg_watch_time"    => 10.0,
      "completion_rate"   => 20.0,
      "engagement_rate"   => 6.4,
      "collected_at"      => Time.current.iso8601,
      "collection_source" => "tiktok_api",
      "raw_data"          => {}
    }]
  end

  let(:fetcher) { instance_double(TikTok::VideoStatsFetcher, call: stats) }

  before do
    allow(TikTok::VideoStatsFetcher).to receive(:new).and_return(fetcher)
  end

  describe "#call" do
    it "enqueues an ingestion job for each video" do
      expect {
        subject.call
      }.to have_enqueued_job(Analytics::IngestVideoAnalyticsJob)
    end

    it "returns success with counts" do
      result = subject.call

      expect(result[:success]).to be true
      expect(result[:collected]).to eq(1)
      expect(result[:queued]).to eq(1)
    end

    it "stamps analytics_last_collected_at on the account" do
      subject.call
      social_account.reload
      expect(social_account.metadata["analytics_last_collected_at"]).to be_present
    end

    context "when account has no videos" do
      before do
        allow(social_account).to receive_message_chain(:videos, :published, :pluck).and_return([])
      end

      it "returns early with zero counts" do
        result = subject.call
        expect(result[:success]).to be true
        expect(result[:queued]).to eq(0)
      end
    end

    context "when account is not active" do
      before { social_account.update!(status: :disconnected) }

      it "returns failure" do
        result = subject.call
        expect(result[:success]).to be false
      end
    end
  end
end
