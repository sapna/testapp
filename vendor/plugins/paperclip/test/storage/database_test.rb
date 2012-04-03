require './test/helper'

def create_table_with_blob_columns
  reset_table :dummies do |table|
    table.column :title, :string
    table.column :other, :string
    table.column :avatar_file_name, :string
    table.column :avatar_content_type, :string
    table.column :avatar_file_size, :integer
    table.column :avatar_updated_at, :datetime
    table.column :avatar_fingerprint, :string
    table.column :custom_file,        :binary
    table.column :special_thumb_file, :binary
  end
end

class DatabaseTest < Test::Unit::TestCase
  context "Database" do
    setup do
      ActiveRecord::Base.clear_active_connections!
      reset_connection
      create_table_with_blob_columns
      rebuild_class :styles => { :thumbnail => { :geometry => "25x25#", :column => 'special_thumb_file' } }, :storage => :database, :column => "custom_file"
      @dummy = Dummy.create!

      @file = File.open(fixture_file('5k.png'), "rb")
      @contents = @file.read
      @file.rewind
      @dummy.avatar = @file
    end

    should "allow file assignment" do
      assert @dummy.save
    end

    should "always return nil for the path" do
      assert @dummy.avatar.path.nil?
      assert @dummy.avatar.path(:thumbnail).nil?
    end

    should "save the file contents to the original style column" do
      assert_equal @contents, @dummy.custom_file
      assert_equal @contents, @dummy.avatar.file_contents
      assert_equal @contents, @dummy.avatar.data
    end

    should "save something to the thumbnail style column" do
      assert !@dummy.special_thumb_file.nil?
    end

    should "clean up file objects" do
      File.stubs(:exist?).returns(true)
      Paperclip::Tempfile.any_instance.expects(:close).at_least_once()
      Paperclip::Tempfile.any_instance.expects(:unlink).at_least_once()

      @dummy.save!
    end

    should "return the meta data columns from select_without_file_columns_for" do
      expected_select_hash = { :select=>"id,title,other,avatar_file_name,avatar_content_type,avatar_file_size,avatar_updated_at,avatar_fingerprint" }
      assert_equal expected_select_hash, Dummy.select_without_file_columns_for(:avatar)
    end
  end
end
