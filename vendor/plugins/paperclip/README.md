Paperclip forked to store files in a database table
=========

This is a fork of Thoughtbot’s fantastic Paperclip gem that supports saving and fetching of file data to/from an RDBMS BLOB column.

Saving file data in a BLOB is a REALLY BAD IDEA - so DON’T USE this fork of Paperclip, unless you are working with a legacy, non-Rails database and you have existing BLOB data you have to work with.
 
Usage is identical to the file system storage version, except in your model specify the `:storage => :database` storage option; for example:

    has_attached_file :avatar, :storage => :database

The file will be stored in a column called `[attachment name]_file` (e.g. `avatar_file`) by default. To specify a different column name, use `:column`, like this:

    has_attached_file :avatar, :storage => :database, :column => 'avatar_data'

If you have defined different styles, these files will be stored in additional columns called `[attachment name]_[style name]_file` (e.g. `avatar_thumb_file`) by default.

To specify different column names for styles, use `:column` in the style definition, like this:

    has_attached_file :avatar,
      :storage => :database,
      :styles => { 
        :medium => {:geometry => "300x300>", :column => 'medium_file'},
        :thumb =>  {:geometry => "100x100>", :column => 'thumb_file'}
      }
 
If you need to create the BLOB columns (remember you should only be using this with a legacy database!!) ...you can use migrations like this:

    add_column :users, :avatar_file,        :binary, :limit => 2.gigabytes
    add_column :users, :avatar_medium_file, :binary, :limit => 1.gigabyte
    add_column :users, :avatar_thumb_file,  :binary, :limit => 200.megabytes

Note the "limit" option (when used for MySQL) will create a BLOB of the appropriate size (up to 4.gigabytes will create a LONGBLOB).

To avoid performance problems loading all of the BLOB columns every time you access your ActiveRecord object, a class method is provided on your model called `select_without_file_columns_for`. This is set to a `:select` scope hash that will instruct `ActiveRecord::Base.find` to load all of the columns except the BLOB/file data columns.
 
You can specify this as a default scope:

    default_scope select_without_file_columns_for(:avatar)

By default, attachment URLs will be set to this pattern:

    /:relative_root/:attachment/:id/:class?style=:style

Example (assuming the relative root is null):

    /users/23/avatars?style=original

And attachments paths will be nil, since they are not stored on the file system. If you need to create a copy of a file attachment on the file system, for example if you need to process it for some reason, use code similar to this:

    begin
      temp_file = Tempfile.open("#{user.avatar_file_name}_#{style}")
      temp_file << user.avatar.file_contents(style)

      ... do something with the temp file ...

    ensure
      temp_file.close
    end

You'll need to download file attachments through a controller. To do that you can use this utility method to generate an `avatars` action for example:

    downloads_files_for :user, :avatar

Or you can write a download method manually if there are security, logging or other requirements. If you prefer a different URL for downloading files you can specify that in the model; e.g.:

     has_attached_file :avatar, :storage => :database, :url => '/users/show_avatar/:id/:style'

Remember to add a route for the download to the controller which will handle downloads, if necessary.

     resources :users do
       get :avatars
     end
