require "rails_helper"

RSpec.describe User, type: :model do
  subject { build(:user) }

  describe "associations" do
    it { should have_many(:social_accounts).dependent(:destroy) }
    it { should have_many(:videos).dependent(:destroy) }
    it { should have_many(:insights).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should have_secure_password }
  end

  describe "#confirmed?" do
    it "returns false when not confirmed" do
      user = build(:user, confirmed_at: nil)
      expect(user.confirmed?).to be false
    end

    it "returns true when confirmed" do
      user = build(:user, :confirmed)
      expect(user.confirmed?).to be true
    end
  end

  describe "#refresh_token_valid?" do
    it "returns false when refresh token is absent" do
      user = build(:user, refresh_token: nil)
      expect(user.refresh_token_valid?).to be false
    end

    it "returns false when refresh token has expired" do
      user = build(:user,
        refresh_token: "abc",
        refresh_token_expires_at: 1.day.ago
      )
      expect(user.refresh_token_valid?).to be false
    end
  end
end
