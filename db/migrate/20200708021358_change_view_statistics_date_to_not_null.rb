class ChangeViewStatisticsDateToNotNull < ActiveRecord::Migration[6.0]
  def change
    change_column_default :view_statistics, :date, nil
    change_column_null :view_statistics, :date, false
  end
end
