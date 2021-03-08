class CreateApplicationSettings < ActiveRecord::Migration[6.0]
  def change
    create_table :application_settings do |t|
      t.string :read_only_message
      t.text :announcement

      t.timestamps
    end
  end
end
