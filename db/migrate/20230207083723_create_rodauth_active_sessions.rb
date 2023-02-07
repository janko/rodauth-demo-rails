class CreateRodauthActiveSessions < ActiveRecord::Migration[7.0]
  def change
    # Used by the active sessions feature
    create_table :account_active_session_keys, primary_key: [:account_id, :session_id] do |t|
      t.references :account, foreign_key: true
      t.string :session_id
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :last_use, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end
  end
end
