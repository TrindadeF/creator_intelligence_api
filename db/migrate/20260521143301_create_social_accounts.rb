class CreateSocialAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :social_accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :provider_account_id, null: false
      t.string :username
      t.text :access_token
      t.text :refresh_token
      t.datetime :token_expires_at
      t.datetime :connected_at
      t.boolean :active, default: true
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :social_accounts, [:user_id, :provider], unique: true
    add_index :social_accounts, [:provider, :provider_account_id], unique: true
    add_index :social_accounts, :active
  end
end
