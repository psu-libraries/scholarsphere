class CreateTinymceAssets < ActiveRecord::Migration[4.2]
  def change
    create_table :tinymce_assets do |t|
      t.string :file
      t.timestamps
    end
  end
end
