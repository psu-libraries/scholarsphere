class CreateAccessControls < ActiveRecord::Migration[6.0]
  def change
    create_table :access_controls do |t|
      t.string :access_level
      t.references :agent, polymorphic: true
      t.references :resource, polymorphic: true

      t.timestamps
    end
  end
end
