class Video < ApplicationRecord
  belongs_to :user
  belongs_to :social_account
  has_many :video_analytics, dependent: :destroy
  has_many :insights, dependent: :nullify

  STATUSES = %w[published archived draft].freeze

  validates :external_video_id, presence: true,
                                uniqueness: { scope: :social_account_id }
  validates :status, inclusion: { in: STATUSES }

  scope :published, -> { where(status: "published") }
  scope :recent, -> { order(published_at: :desc) }
  scope :by_platform, ->(provider) { joins(:social_account).where(social_accounts: { provider: provider }) }

  def latest_analytics
    video_analytics.order(collected_at: :desc).first
  end

  def analytics_for_period(start_date, end_date)
    video_analytics.where(collected_at: start_date..end_date).order(collected_at: :asc)
  end

  def hashtags_list
    hashtags.is_a?(Array) ? hashtags : []
  end
end
