class CreateInsights < ActiveRecord::Migration[8.0]
  def change
    create_table :insights do |t|
      t.references :user, null: false, foreign_key: true
      t.references :video, null: true, foreign_key: true
      t.string :insight_type, null: false
      t.string :title, null: false
      t.text :description
      t.text :ai_summary
      t.string :severity, default: "info"
      t.boolean :read, default: false
      t.boolean :dismissed, default: false
      t.string :generated_by, default: "system"
      t.jsonb :metadata, default: {}
      t.datetime :expires_at

      t.timestamps
    end

    add_index :insights, :user_id
    add_index :insights, :video_id
    add_index :insights, :insight_type
    add_index :insights, :severity
    add_index :insights, :read
    add_index :insights, [:user_id, :created_at]
  end
end
