module JwtConfig
  SECRET_KEY = ENV.fetch("JWT_SECRET_KEY", Rails.application.secret_key_base)
  EXPIRATION_HOURS = ENV.fetch("JWT_EXPIRATION_HOURS", 24).to_i
  REFRESH_EXPIRATION_DAYS = ENV.fetch("JWT_REFRESH_EXPIRATION_DAYS", 30).to_i
end
