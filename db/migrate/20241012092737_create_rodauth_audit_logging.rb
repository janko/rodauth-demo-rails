class CreateRodauthAuditLogging < ActiveRecord::Migration[7.2]
  def change
    # Used by the audit logging feature
    create_table :account_authentication_audit_logs do |t|
      t.references :account, foreign_key: true, null: false
      t.datetime :at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.text :message, null: false
      t.json :metadata
      t.index [:account_id, :at]
      t.index :at
    end
  end
end
