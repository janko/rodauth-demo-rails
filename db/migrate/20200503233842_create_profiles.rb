class CreateProfiles < ActiveRecord::Migration[6.0]
  def change
    create_table :profiles do |t|
      t.references :account, foreign_key: true

      t.string :name, null: false
    end
  end
end
