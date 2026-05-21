class VideoSerializer < Blueprinter::Base
  identifier :id

  fields :title, :description, :duration_seconds, :published_at,
         :thumbnail_url, :video_url, :status, :hashtags, :created_at

  field :external_video_id do |video|
    video.external_video_id
  end

  field :platform do |video|
    video.social_account&.provider
  end

  view :with_latest_analytics do
    fields :title, :description, :duration_seconds, :published_at,
           :thumbnail_url, :video_url, :status, :hashtags

    association :latest_analytics, blueprint: VideoAnalyticSerializer do |video|
      video.latest_analytics
    end
  end
end
