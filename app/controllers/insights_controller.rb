class InsightsController < ApplicationController
  def index
    insights = current_user.insights.active.recent
    insights = insights.where(insight_type: params[:type]) if params[:type].present?
    insights = insights.where(severity: params[:severity]) if params[:severity].present?
    insights = insights.unread if params[:unread] == "true"

    pagy, paginated = pagy(insights)

    render json: {
      data: InsightSerializer.render_as_hash(paginated),
      meta: pagy_metadata_response(pagy)
    }
  end

  def mark_read
    insight = current_user.insights.find(params[:id])
    insight.read!
    render json: { message: "Insight marked as read" }
  end

  def dismiss
    insight = current_user.insights.find(params[:id])
    insight.dismiss!
    render json: { message: "Insight dismissed" }
  end
end
