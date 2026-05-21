class VideoAnalytic < ApplicationRecord
  belongs_to :video

  validates :collected_at, presence: true
  validates :views, numericality: { greater_than_or_equal_to: 0 }
  validates :engagement_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  scope :recent, -> { order(collected_at: :desc) }
  scope :for_period, ->(start_date, end_date) { where(collected_at: start_date..end_date) }
  scope :with_views, -> { where("views > 0") }

  def calculate_engagement_rate
    return 0.0 if views.zero?

    interactions = likes + comments + shares + saves
    ((interactions.to_f / views) * 100).round(2)
  end
end
