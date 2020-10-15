class CreateExternalApps < ActiveRecord::Migration[6.0]
  def change
    create_table :external_apps do |t|
      t.string :name
      t.string :contact_email

      t.timestamps
    end

    add_index :external_apps, :name, unique: true
  end
end
