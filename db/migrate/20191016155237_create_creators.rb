class CreateCreators < ActiveRecord::Migration[6.0]
  def change
    create_table :creators do |t|
      t.string :surname
      t.string :given_name
      t.string :email
      t.string :psu_id
      t.string :orcid

      t.timestamps
    end
  end
end
