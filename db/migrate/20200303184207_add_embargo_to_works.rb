class AddEmbargoToWorks < ActiveRecord::Migration[6.0]
  def change
    add_column :works, :embargoed_until, :datetime
  end
end
