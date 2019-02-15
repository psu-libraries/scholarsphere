class CreateTrophies < ActiveRecord::Migration[4.2]
  def change
    create_table :trophies do |t|
      t.integer :user_id
      t.string :generic_file_id

      t.timestamps
    end
  end
end
