source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.3"

gem "rails", "~> 8.0"
gem "pg", "~> 1.1"
gem "puma", "~> 6.0"
gem "bootsnap", require: false
gem "rack-cors"

# Auth
gem "jwt", "~> 2.9"
gem "bcrypt", "~> 3.1"

# Background Jobs
gem "sidekiq", "~> 7.3"
gem "sidekiq-cron", "~> 1.12"
gem "redis", "~> 5.0"

# Serializers
gem "blueprinter", "~> 1.0"

# Pagination
gem "pagy", "~> 9.0"

# Rate limiting
gem "rack-attack"

# Environment variables
gem "dotenv-rails"

# HTTP client (for TikTok API)
gem "faraday", "~> 2.10"
gem "faraday-retry"

group :development, :test do
  gem "debug", platforms: %i[mri windows]
  gem "rspec-rails", "~> 6.1"
  gem "factory_bot_rails"
  gem "faker"
  gem "shoulda-matchers"
end

group :development do
  gem "spring"
  gem "letter_opener_web", "~> 3.0"
end

group :test do
  gem "database_cleaner-active_record"
end
