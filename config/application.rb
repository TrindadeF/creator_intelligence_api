require_relative "boot"
require "rails/all"

Bundler.require(*Rails.groups)

module CreatorIntelligenceApi
  class Application < Rails::Application
    config.load_defaults 8.0
    config.api_only = true
    config.time_zone = "UTC"
    config.active_job.queue_adapter = :sidekiq
    config.middleware.use Rack::Attack

    config.autoload_paths += [
      Rails.root.join("app/services").to_s,
      Rails.root.join("app/queries").to_s,
      Rails.root.join("app/policies").to_s,
      Rails.root.join("app/presenters").to_s,
      Rails.root.join("app/serializers").to_s
    ]
  end
end
