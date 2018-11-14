class CreateMergeRequestPipelinesTable < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :merge_request_pipelines do |t|
      t.references :merge_request, null: false, index: true, foreign_key: { on_delete: :cascade }
      t.references :ci_pipeline, null: false, index: true, foreign_key: { on_delete: :cascade }

      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false
    end
  end
end
