FactoryBot.define do
  factory :user do
    name { Faker::Name.full_name }
    email { Faker::Internet.unique.email }
    password { "Password123!" }
    password_confirmation { "Password123!" }
    niche { User::NICHES.sample }
    bio { Faker::Lorem.sentence }
    active { true }

    trait :confirmed do
      confirmed_at { Time.current }
      confirmation_token { nil }
    end

    trait :unconfirmed do
      confirmed_at { nil }
    end
  end
end
