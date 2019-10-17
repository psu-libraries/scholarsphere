class CreateWorks < ActiveRecord::Migration[6.0]
  def change
    create_table :works do |t|
      t.string :work_type
      t.integer :depositor_id

      t.timestamps
    end

    add_index :works, :depositor_id
    add_foreign_key :works, :users, column: :depositor_id
  end
end
