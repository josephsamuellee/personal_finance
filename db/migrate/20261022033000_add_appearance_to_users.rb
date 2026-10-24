class AddAppearanceToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :appearance, :string, null: false, default: "system"
  end
end
