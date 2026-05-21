FactoryBot.define do
  factory :video do
    association :user
    association :social_account
    external_video_id { Faker::Alphanumeric.alphanumeric(number: 15) }
    title { Faker::Lorem.sentence(word_count: 5) }
    description { Faker::Lorem.paragraph }
    duration_seconds { rand(15..180) }
    published_at { Faker::Time.backward(days: 30) }
    status { "published" }
    hashtags { ["#trending", "#viral"] }
  end
end
