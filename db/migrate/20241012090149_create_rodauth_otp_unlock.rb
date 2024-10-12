class CreateRodauthOtpUnlock < ActiveRecord::Migration[7.2]
  def change
    # Used by the otp_unlock feature
    create_table :account_otp_unlocks, id: false do |t|
      t.bigint :id, primary_key: true
      t.foreign_key :accounts, column: :id
      t.integer :num_successes, null: false, default: 1
      t.datetime :next_auth_attempt_after, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end
  end
end
