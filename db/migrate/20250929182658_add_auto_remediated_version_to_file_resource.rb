class AddAutoRemediatedVersionToFileResource < ActiveRecord::Migration[7.2]
  def change
    add_column :file_resources, :auto_remediated_version, :boolean, default: false, null: false
  end
end
