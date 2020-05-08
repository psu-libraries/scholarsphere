class AddIndexOnAccessLevelToAccessControls < ActiveRecord::Migration[6.0]
  def change
    add_index :access_controls,
      [:access_level, :agent_type, :resource_type, :agent_id, :resource_id],
      name: 'index_access_controls_on_access_level_agent_and_resource',
      unique: true
  end
end
