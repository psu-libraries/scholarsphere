class CreateAuthorships < ActiveRecord::Migration[6.0]
  def change
    create_table :authorships do |t|
      t.string :alias
      t.string :given_name
      t.string :surname
      t.string :email
      t.integer :position 
      t.string :instance_token

      t.references :resource, polymorphic: true
      t.references :actor, null: true, foreign_key: true

      t.timestamps
    end

    add_index :authorships, :instance_token, unique: false
  end
end
