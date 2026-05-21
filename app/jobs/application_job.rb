class ApplicationJob < ActiveJob::Base
  rescue_from StandardError do |e|
    Rails.logger.error("[#{self.class.name}] Error: #{e.message}")
    raise
  end
end
