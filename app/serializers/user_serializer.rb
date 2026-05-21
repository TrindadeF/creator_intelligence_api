class UserSerializer < Blueprinter::Base
  identifier :id

  fields :name, :email, :avatar_url, :niche, :bio, :confirmed_at, :created_at, :updated_at

  view :public do
    fields :name, :avatar_url, :niche, :bio
  end

  view :with_stats do
    fields :name, :email, :avatar_url, :niche, :bio, :confirmed_at

    field :social_accounts_count do |user|
      user.social_accounts.active.count
    end

    field :videos_count do |user|
      user.videos.published.count
    end
  end
end
