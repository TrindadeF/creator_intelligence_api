class User < ApplicationRecord
  has_secure_password

  has_many :social_accounts, dependent: :destroy
  has_many :videos, dependent: :destroy
  has_many :insights, dependent: :destroy

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true

  before_save :downcase_email
  before_create :generate_confirmation_token

  scope :active, -> { where(active: true) }
  scope :confirmed, -> { where.not(confirmed_at: nil) }

  NICHES = %w[comedy education lifestyle fitness beauty tech gaming travel food music art dance].freeze

  def confirmed?
    confirmed_at.present?
  end

  def confirm!
    update!(confirmed_at: Time.current, confirmation_token: nil)
  end

  def generate_password_reset_token!
    update!(
      reset_password_token: SecureRandom.urlsafe_base64(32),
      reset_password_sent_at: Time.current
    )
  end

  def password_reset_token_valid?
    reset_password_sent_at.present? &&
      reset_password_sent_at > 2.hours.ago
  end

  def generate_refresh_token!
    token = SecureRandom.urlsafe_base64(64)
    update!(
      refresh_token: token,
      refresh_token_expires_at: JwtConfig::REFRESH_EXPIRATION_DAYS.days.from_now
    )
    token
  end

  def refresh_token_valid?
    refresh_token.present? &&
      refresh_token_expires_at.present? &&
      refresh_token_expires_at > Time.current
  end

  def invalidate_refresh_token!
    update!(refresh_token: nil, refresh_token_expires_at: nil)
  end

  private

  def downcase_email
    self.email = email.downcase.strip
  end

  def generate_confirmation_token
    self.confirmation_token = SecureRandom.urlsafe_base64(32)
    self.confirmation_sent_at = Time.current
  end
end
