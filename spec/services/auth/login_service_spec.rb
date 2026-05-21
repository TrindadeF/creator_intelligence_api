require "rails_helper"

RSpec.describe Auth::LoginService, type: :service do
  let(:user) { create(:user, :confirmed, email: "test@example.com", password: "Password123!") }

  describe "#call" do
    context "with valid credentials" do
      it "returns success with token" do
        result = described_class.new(email: user.email, password: "Password123!").call

        expect(result[:success]).to be true
        expect(result[:token]).to be_present
        expect(result[:refresh_token]).to be_present
        expect(result[:user]).to eq(user)
      end
    end

    context "with invalid password" do
      it "returns failure" do
        result = described_class.new(email: user.email, password: "wrong").call

        expect(result[:success]).to be false
        expect(result[:error]).to eq("Invalid email or password")
      end
    end

    context "with non-existent email" do
      it "returns failure" do
        result = described_class.new(email: "nobody@example.com", password: "Password123!").call

        expect(result[:success]).to be false
      end
    end
  end
end
