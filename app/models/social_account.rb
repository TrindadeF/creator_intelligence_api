class SocialAccount < ApplicationRecord
  belongs_to :user
  has_many :videos, dependent: :destroy

  PROVIDERS = %w[tiktok youtube instagram].freeze

  validates :provider, presence: true, inclusion: { in: PROVIDERS }
  validates :provider_account_id, presence: true
  validates :provider, uniqueness: { scope: :user_id, message: "already connected for this user" }

  scope :active, -> { where(active: true) }
  scope :by_provider, ->(provider) { where(provider: provider) }
  scope :tiktok, -> { by_provider("tiktok") }
  scope :youtube, -> { by_provider("youtube") }
  scope :instagram, -> { by_provider("instagram") }

  def disconnect!
    update!(active: false, access_token: nil, refresh_token: nil)
  end

  def token_expired?
    token_expires_at.present? && token_expires_at < Time.current
  end
end
