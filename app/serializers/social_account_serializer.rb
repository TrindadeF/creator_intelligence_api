class SocialAccountSerializer < Blueprinter::Base
  identifier :id

  fields :provider, :username, :connected_at, :active, :created_at

  field :provider_account_id do |account|
    account.provider_account_id
  end

  field :has_valid_token do |account|
    account.access_token.present? && !account.token_expired?
  end
end
