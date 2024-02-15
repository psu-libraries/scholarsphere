class CreateCuratorships < ActiveRecord::Migration[6.1]
  def change
    create_table :curatorships do |t|
      t.references :user, foreign_key: true
      t.references :work, foreign_key: true

      t.timestamps
    end

    remove_column :works, :curator_id
  end
end
