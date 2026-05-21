class UsersController < ApplicationController
  def me
    render json: {
      data: UserSerializer.render_as_hash(current_user, view: :with_stats)
    }
  end

  def update_me
    if current_user.update(user_params)
      render json: {
        data: UserSerializer.render_as_hash(current_user)
      }
    else
      render_error("Update failed", errors: current_user.errors.full_messages)
    end
  end

  private

  def user_params
    params.permit(:name, :avatar_url, :niche, :bio)
  end
end
