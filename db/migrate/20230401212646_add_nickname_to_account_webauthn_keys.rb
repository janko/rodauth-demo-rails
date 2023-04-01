class AddNicknameToAccountWebauthnKeys < ActiveRecord::Migration[7.0]
  def change
    add_column :account_webauthn_keys, :nickname, :string
  end
end
