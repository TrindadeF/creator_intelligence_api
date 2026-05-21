class InsightSerializer < Blueprinter::Base
  identifier :id

  fields :insight_type, :title, :description, :ai_summary,
         :severity, :read, :dismissed, :generated_by,
         :metadata, :created_at

  field :video_id do |insight|
    insight.video_id
  end
end
