class CreateRodauth < ActiveRecord::Migration[6.0]
  class AccountStatus < ActiveRecord::Base; end

  def change
    enable_extension "citext"

    # Used by the account verification and close account features
    create_table :account_statuses do |t|
      t.string :name, null: false, unique: true
    end
    AccountStatus.create [{ name: "Unverified" }, { name: "Verified" }, { name: "Closed" }]

    create_table :accounts do |t|
      t.integer :status_id
      t.foreign_key :account_statuses, column: :status_id, null: false
      t.citext :email, null: false
      t.index :email, unique: true, where: "status_id IN (1, 2)"
      t.string :password_hash
    end

    deadline_opts = proc do |days|
      { null: false, default: -> { "CURRENT_TIMESTAMP + interval '#{days} day'" } }
    end

    # Used by the password reset feature
    create_table :account_password_reset_keys do |t|
      t.foreign_key :accounts, column: :id
      t.string :key, null: false
      t.datetime :deadline, deadline_opts[1]
      t.datetime :email_last_sent, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    # Used by the account verification feature
    create_table :account_verification_keys do |t|
      t.foreign_key :accounts, column: :id
      t.string :key, null: false
      t.column :requested_at, :datetime, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.column :email_last_sent, :datetime, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    # Used by the verify login change feature
    create_table :account_login_change_keys do |t|
      t.foreign_key :accounts, column: :id
      t.string :key, null: false
      t.string :login, null: false
      t.datetime :deadline, deadline_opts[1]
    end

    # Used by the remember me feature
    create_table :account_remember_keys do |t|
      t.foreign_key :accounts, column: :id
      t.string :key, null: false
      t.datetime :deadline, deadline_opts[1]
    end

    # Used by the lockout feature
    create_table :account_login_failures do |t|
      t.foreign_key :accounts, column: :id
      t.integer :number, null: false, default: 1
    end
    create_table :account_lockouts do |t|
      t.foreign_key :accounts, column: :id
      t.string :key, null: false
      t.datetime :deadline, deadline_opts[1]
      t.datetime :email_last_sent
    end

    # Used by the email auth feature
    create_table :account_email_auth_keys do |t|
      t.foreign_key :accounts, column: :id
      t.string :key, null: false
      t.datetime :deadline, deadline_opts[1]
      t.datetime :email_last_sent, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    # Used by the password expiration feature
    create_table :account_password_change_times do |t|
      t.foreign_key :accounts, column: :id
      t.datetime :changed_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    # Used by the account expiration feature
    create_table :account_activity_times do |t|
      t.foreign_key :accounts, column: :id
      t.datetime :last_activity_at, null: false
      t.datetime :last_login_at, null: false
      t.datetime :expired_at
    end

    # Used by the single session feature
    create_table :account_session_keys do |t|
      t.foreign_key :accounts, column: :id
      t.string :key, null: false
    end

    # Used by the otp feature
    create_table :account_otp_keys do |t|
      t.foreign_key :accounts, column: :id
      t.string :key, null: false
      t.integer :num_failures, null: false, default: 0
      t.datetime :last_use, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    # Used by the recovery codes feature
    create_table :account_recovery_codes, primary_key: [:id, :code] do |t|
      t.integer :id
      t.foreign_key :accounts, column: :id
      t.string :code
    end

    # Used by the sms codes feature
    create_table :account_sms_codes do |t|
      t.foreign_key :accounts, column: :id
      t.string :phone_number, null: false
      t.integer :num_failures
      t.string :code
      t.datetime :code_issued_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end
  end
end
