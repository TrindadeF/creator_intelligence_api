class CreateVideoAnalytics < ActiveRecord::Migration[8.0]
  def change
    create_table :video_analytics do |t|
      t.references :video, null: false, foreign_key: true
      t.bigint :views, default: 0
      t.bigint :likes, default: 0
      t.bigint :comments, default: 0
      t.bigint :shares, default: 0
      t.bigint :saves, default: 0
      t.bigint :watch_time, default: 0
      t.decimal :avg_watch_time, precision: 10, scale: 2, default: 0
      t.decimal :retention_rate, precision: 5, scale: 2, default: 0
      t.decimal :completion_rate, precision: 5, scale: 2, default: 0
      t.decimal :engagement_rate, precision: 5, scale: 2, default: 0
      t.integer :followers_gained, default: 0
      t.decimal :revenue, precision: 10, scale: 2, default: 0
      t.datetime :collected_at, null: false
      t.string :collection_source, default: "api"
      t.jsonb :raw_data, default: {}

      t.timestamps
    end

    # video_id index is created automatically by t.references
    add_index :video_analytics, :collected_at
    add_index :video_analytics, [:video_id, :collected_at]
    add_index :video_analytics, :views
    add_index :video_analytics, :engagement_rate
  end
end
