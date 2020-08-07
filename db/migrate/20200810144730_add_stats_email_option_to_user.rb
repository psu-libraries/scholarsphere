class AddStatsEmailOptionToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :opt_out_stats_email, :boolean, default: false
  end
end
