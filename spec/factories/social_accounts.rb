FactoryBot.define do
  factory :social_account do
    association :user
    provider { "tiktok" }
    provider_account_id { Faker::Alphanumeric.alphanumeric(number: 20) }
    username { Faker::Internet.username }
    access_token { SecureRandom.hex(32) }
    active { true }
    connected_at { Time.current }
  end
end
