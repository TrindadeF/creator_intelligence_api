FactoryBot.define do
  factory :insight do
    association :user
    insight_type { Insight::TYPES.sample }
    title { Faker::Lorem.sentence(word_count: 5) }
    description { Faker::Lorem.paragraph }
    severity { "info" }
    generated_by { "system" }
    read { false }
    dismissed { false }
  end
end
