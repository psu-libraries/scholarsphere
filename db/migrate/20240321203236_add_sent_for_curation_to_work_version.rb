class AddSentForCurationToWorkVersion < ActiveRecord::Migration[6.1]
  def change
    add_column :work_versions, :sent_for_curation, :datetime
  end
end
