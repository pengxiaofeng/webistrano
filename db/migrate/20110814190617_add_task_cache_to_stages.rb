class AddTaskCacheToStages < ActiveRecord::Migration
  def self.up
    add_column :stages, :tasks_cache, :text
  end

  def self.down
    remove_column :stages, :tasks_cache
  end
end
