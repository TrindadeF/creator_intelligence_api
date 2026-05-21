class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :avatar_url
      t.string :niche
      t.text :bio
      t.string :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.string :refresh_token
      t.datetime :refresh_token_expires_at
      t.boolean :active, default: true, null: false
      t.jsonb :settings, default: {}

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :confirmation_token, unique: true
    add_index :users, :reset_password_token
    add_index :users, :refresh_token
    add_index :users, :active
  end
end
