module TikTokConfig
  CLIENT_KEY    = ENV.fetch("TIKTOK_CLIENT_KEY", "")
  CLIENT_SECRET = ENV.fetch("TIKTOK_CLIENT_SECRET", "")
  REDIRECT_URI  = ENV.fetch("TIKTOK_REDIRECT_URI", "http://localhost:3000/auth/tiktok/callback")

  SCOPES = %w[
    user.info.basic
    user.info.profile
    user.info.stats
    video.list
  ].freeze

  STATE_TTL_SECONDS = 600 # 10 minutes
end

module TikTok
  class Error        < StandardError; end
  class AuthError    < Error; end
  class ApiError     < Error; end
  class TokenExpired < Error; end
end
