class ChangeWorksDepositorFks < ActiveRecord::Migration[6.0]
  def change
    delete_database # prenvent FK constraint errors

    remove_reference :works, :depositor, null: false, foreign_key: { to_table: :users }

    add_reference :works, :depositor, null: false, foreign_key: { to_table: :actors }
    add_reference :works, :proxy, null: true, foreign_key: { to_table: :actors }
  end

  def delete_database
    execute <<~SQL
      DELETE from file_resources;
      DELETE from file_version_memberships;
      DELETE from work_version_creations;
      DELETE from work_versions;
      DELETE from legacy_identifiers;
      DELETE from works;

      DELETE from access_controls;
      DELETE from user_group_memberships;
      DELETE from users;

      DELETE from actors;
    SQL
  end
end
