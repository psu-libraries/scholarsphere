class AddOptInStatsEmailToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :opt_in_stats_email, :boolean, default: true

    populate_opt_in_stats_email
  end

  def populate_opt_in_stats_email
    execute <<~SQL
      UPDATE users SET opt_in_stats_email = false WHERE opt_out_stats_email = true
    SQL
  end
end
