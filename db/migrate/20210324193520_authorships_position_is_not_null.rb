class AuthorshipsPositionIsNotNull < ActiveRecord::Migration[6.0]
  def change
    change_column_null(:authorships, :position, false)
  end
end
