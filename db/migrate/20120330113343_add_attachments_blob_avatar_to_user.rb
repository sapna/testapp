class AddAttachmentsBlobAvatarToUser < ActiveRecord::Migration
 def self.up
    execute 'ALTER TABLE users ADD COLUMN avatar_file LONGBLOB'
    execute 'ALTER TABLE users ADD COLUMN avatar_small_file LONGBLOB'
    execute 'ALTER TABLE users ADD COLUMN avatar_thumb_file LONGBLOB'
    add_column :users, :avatar_content_type, :string
    add_column :users, :avatar_file_name, :string
    add_column :users, :avatar_file_size, :integer
  end

  def self.down
    remove_column :users, :avatar_file
    remove_column :users, :avatar_small_file
    remove_column :users, :avatar_thumb_file
    remove_column :users, :avatar_content_type
    remove_column :users, :avatar_file_name
    remove_column :users, :avatar_file_size
  end
end
