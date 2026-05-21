require "rails_helper"

RSpec.describe "Auth", type: :request do
  describe "POST /auth/register" do
    let(:valid_params) do
      {
        name: "John Creator",
        email: "john@example.com",
        password: "Password123!",
        password_confirmation: "Password123!",
        niche: "comedy"
      }
    end

    it "registers a new user" do
      post "/auth/register", params: valid_params

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["data"]["token"]).to be_present
      expect(json["data"]["user"]["email"]).to eq("john@example.com")
    end

    it "returns errors for invalid data" do
      post "/auth/register", params: { name: "", email: "invalid", password: "123" }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /auth/login" do
    let!(:user) { create(:user, :confirmed, email: "creator@example.com", password: "Password123!") }

    it "logs in with valid credentials" do
      post "/auth/login", params: { email: user.email, password: "Password123!" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"]["token"]).to be_present
    end

    it "rejects invalid credentials" do
      post "/auth/login", params: { email: user.email, password: "wrong" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /me" do
    let(:user) { create(:user, :confirmed) }

    it "returns current user" do
      get "/me", headers: auth_headers_for(user)
      expect(response).to have_http_status(:ok)
    end

    it "returns 401 without auth" do
      get "/me"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
