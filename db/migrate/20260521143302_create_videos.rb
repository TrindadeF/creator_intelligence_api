class CreateVideos < ActiveRecord::Migration[8.0]
  def change
    create_table :videos do |t|
      t.references :user, null: false, foreign_key: true
      t.references :social_account, null: false, foreign_key: true
      t.string :external_video_id, null: false
      t.string :title
      t.text :description
      t.integer :duration_seconds
      t.datetime :published_at
      t.string :thumbnail_url
      t.string :video_url
      t.string :status, default: "published"
      t.jsonb :hashtags, default: []
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :videos, [:social_account_id, :external_video_id], unique: true
    # user_id index is created automatically by t.references
    add_index :videos, :published_at
    add_index :videos, :status
    add_index :videos, :external_video_id
  end
end
