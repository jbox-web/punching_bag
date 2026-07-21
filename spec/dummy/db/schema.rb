# frozen_string_literal: true

ActiveRecord::Schema.define do
  create_table(:articles, force: true) do |t|
    t.string :title
    t.text   :content
    t.timestamps
  end

  create_table(:punches, force: true) do |t|
    t.integer  :punchable_id,   null: false
    t.string   :punchable_type, null: false
    t.datetime :starts_at,      null: false
    t.datetime :ends_at,        null: false
    t.datetime :average_time,   null: false
    t.integer  :hits,           null: false, default: 1
  end

  add_index :punches, [:average_time], name: 'index_punches_on_average_time'
  add_index :punches, %i[punchable_type punchable_id], name: 'punchable_index'

  # acts-as-taggable-on tables (for the ActsAsTaggableOn integration specs)
  create_table(:tags, force: true) do |t|
    t.string  :name
    t.integer :taggings_count, default: 0
    t.timestamps
  end

  create_table(:taggings, force: true) do |t|
    t.references :tag
    t.references :taggable, polymorphic: true
    t.references :tagger,   polymorphic: true
    t.string     :context, limit: 128
    t.string     :tenant,  limit: 128
    t.datetime   :created_at
  end

  add_index :taggings, %i[taggable_id taggable_type context], name: 'taggings_taggable_context_idx'
end
