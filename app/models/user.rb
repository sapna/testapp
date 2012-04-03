class User < ActiveRecord::Base
  has_attached_file :avatar,
                    :storage => :database,
                    :styles => { :thumb => "75x75>", :small => "150x150>" },
                    #:url => '/users/show_avatar/:id/:style'
                    :url => '/users/:id/avatars?style=:style'
  #default_scope select_without_file_columns_for(:avatar)
  attr_accessor :avatar_file_name
  #validates_attachment_content_type :avatar, :content_type => 'image/jpeg'
  validates_attachment_content_type :avatar, :content_type => 'application/x-pkcs12'
end
