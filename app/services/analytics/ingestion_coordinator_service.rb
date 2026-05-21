module Analytics
  # Provider-agnostic coordinator that routes analytics collection
  # to the correct provider-specific ingestion service.
  #
  # Called by CollectAllAnalyticsJob for each active social account.
  class IngestionCoordinatorService
    PROVIDER_SERVICES = {
      "tiktok"    => "TikTok::AnalyticsIngestionService",
      "youtube"   => nil, # future
      "instagram" => nil  # future
    }.freeze

    def initialize(social_account:)
      @account = social_account
    end

    def call
      service_class_name = PROVIDER_SERVICES[@account.provider]

      unless service_class_name
        return {
          success: false,
          error:   "No ingestion service for provider: #{@account.provider}"
        }
      end

      service_class = service_class_name.constantize
      service_class.new(social_account: @account).call
    end
  end
end
