require "rails_helper"

RSpec.describe Analytics::CollectAllAnalyticsJob do
  let!(:active_account)       { create(:social_account, provider: :tiktok) }
  let!(:disconnected_account) { create(:social_account, provider: :tiktok, status: :disconnected) }

  describe "#perform" do
    it "enqueues CollectAccountAnalyticsJob only for active accounts" do
      expect {
        described_class.new.perform
      }.to have_enqueued_job(Analytics::CollectAccountAnalyticsJob)
        .with(active_account.id)

      expect(Analytics::CollectAccountAnalyticsJob).not_to have_been_enqueued.with(disconnected_account.id)
    end
  end
end
