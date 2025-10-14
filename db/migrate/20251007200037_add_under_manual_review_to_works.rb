class AddUnderManualReviewToWorks < ActiveRecord::Migration[7.2]
  def change
    add_column :works, :under_manual_review, :boolean
  end
end
