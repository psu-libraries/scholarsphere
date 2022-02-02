class RemoveOptOutStatsEmailFromUsers < ActiveRecord::Migration[6.1]
  def change
    remove_column :users, :opt_out_stats_email, :boolean
  end
end
