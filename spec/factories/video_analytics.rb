FactoryBot.define do
  factory :video_analytic do
    association :video
    views { rand(100..100_000) }
    likes { rand(10..10_000) }
    comments { rand(1..1_000) }
    shares { rand(1..500) }
    saves { rand(1..500) }
    watch_time { rand(1000..100_000) }
    avg_watch_time { rand(5.0..60.0).round(2) }
    retention_rate { rand(20.0..80.0).round(2) }
    completion_rate { rand(10.0..70.0).round(2) }
    engagement_rate { rand(1.0..15.0).round(2) }
    followers_gained { rand(0..500) }
    collected_at { Time.current }
  end
end
