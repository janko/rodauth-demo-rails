class AddTypeToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :type, :string, null: false, default: "main"
  end
end
