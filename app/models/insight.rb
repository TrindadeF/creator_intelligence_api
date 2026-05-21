class Insight < ApplicationRecord
  belongs_to :user
  belongs_to :video, optional: true

  TYPES = %w[
    best_posting_time
    retention_drop
    format_performance
    weak_hook
    long_video_underperform
    engagement_spike
    follower_growth
    trending_hashtag
    content_gap
    benchmark_alert
  ].freeze

  SEVERITIES = %w[info warning critical success].freeze
  GENERATORS = %w[system ai manual].freeze

  validates :insight_type, presence: true, inclusion: { in: TYPES }
  validates :title, presence: true
  validates :severity, inclusion: { in: SEVERITIES }
  validates :generated_by, inclusion: { in: GENERATORS }

  scope :unread, -> { where(read: false) }
  scope :active, -> { where(dismissed: false).where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :by_type, ->(type) { where(insight_type: type) }
  scope :by_severity, ->(severity) { where(severity: severity) }
  scope :recent, -> { order(created_at: :desc) }

  def read!
    update!(read: true)
  end

  def dismiss!
    update!(dismissed: true)
  end
end
