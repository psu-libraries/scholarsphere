class AddActorIdToUsers < ActiveRecord::Migration[6.0]
  def change
    # Must do this because we can't have any NULLs in the users.actor_id column
    # and therefore must blow all users away first.
    delete_database

    add_reference :users, :actor, null: false, foreign_key: true
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
