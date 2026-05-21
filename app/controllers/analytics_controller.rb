class AnalyticsController < ApplicationController
  def overview
    period = params.fetch(:period, 30).to_i
    result = Analytics::OverviewCalculator.new(user: current_user, period: period).call

    render json: { data: result }
  end

  def video
    video = current_user.videos.find(params[:id])
    analytics = video.video_analytics.recent

    pagy, paginated = pagy(analytics)

    render json: {
      data: VideoAnalyticSerializer.render_as_hash(paginated),
      meta: pagy_metadata_response(pagy)
    }
  end

  def trends
    period = params.fetch(:period, 30).to_i
    start_date = period.days.ago

    analytics = VideoAnalytic
      .joins(video: :user)
      .where(users: { id: current_user.id })
      .where(collected_at: start_date..Time.current)
      .order(collected_at: :asc)
      .select(:collected_at, :views, :engagement_rate, :video_id)

    render json: { data: analytics }
  end
end
