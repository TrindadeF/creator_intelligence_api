class VideosController < ApplicationController
  def index
    videos = current_user.videos.published.recent
    pagy, paginated_videos = pagy(videos)

    render json: {
      data: VideoSerializer.render_as_hash(paginated_videos, view: :with_latest_analytics),
      meta: pagy_metadata_response(pagy)
    }
  end

  def show
    video = current_user.videos.find(params[:id])
    render json: {
      data: VideoSerializer.render_as_hash(video, view: :with_latest_analytics)
    }
  end
end
