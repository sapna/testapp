Feature: Rails integration

  Background:
    Given I generate a new rails application
    And I run a rails generator to generate a "User" scaffold with "name:string"
    And I run a paperclip generator to add a paperclip "attachment" to the "User" model
    And I run a migration
    And I update my new user view to include the file upload field
    And I update my user view to include the attachment

  Scenario: Filesystem integration test
    Given I add this snippet to the User model:
      """
      has_attached_file :attachment
      """
    And I start the rails application
    When I go to the new user page
    And I fill in "Name" with "something"
    And I attach the file "test/fixtures/5k.png" to "Attachment"
    And I press "Submit"
    Then I should see "Name: something"
    And I should see an image with a path of "/system/attachments/1/original/5k.png"
    And the file at "/system/attachments/1/original/5k.png" should be the same as "test/fixtures/5k.png"

  Scenario: S3 Integration test
    Given I add this snippet to the User model:
      """
      has_attached_file :attachment,
                        :storage => :s3,
                        :path => "/:attachment/:id/:style/:filename",
                        :s3_credentials => Rails.root.join("config/s3.yml")
      """
    And I write to "config/s3.yml" with:
      """
      bucket: paperclip
      access_key_id: access_key
      secret_access_key: secret_key
      """
    And I start the rails application
    When I go to the new user page
    And I fill in "Name" with "something"
    And I attach the file "test/fixtures/5k.png" to "Attachment" on S3
    And I press "Submit"
    Then I should see "Name: something"
    And I should see an image with a path of "http://s3.amazonaws.com/paperclip/attachments/1/original/5k.png"
    And the file at "http://s3.amazonaws.com/paperclip/attachments/1/original/5k.png" should be uploaded to S3

  Scenario: Database storage integration test
    Given I add this snippet to the User model:
      """
      has_attached_file :attachment, :storage => :database
      """
    And I add this snippet to the Users controller:
      """
      downloads_files_for :user, :attachment
      """
    And I run a rails generator to generate a "add_blob_to_users" migration
    And I write to the "add_blob_to_users" migration file with:
      """
      class AddBlobToUsers < ActiveRecord::Migration
        def self.up
          add_column :users, :attachment_file, :binary
        end
        def self.down
          remove_column :users, :attachment_file, :binary
        end
      end
      """
    And I run a migration
    And I replace the users resources route with this one for Rails 3:
      """
      resources :users do
        get :attachments
      end
      """
    And I replace the users resources route with this one for Rails 2:
      """
      map.resources :users, :member => {:attachments => :get}
      """
    And I start the rails application
    When I go to the new user page
    And I fill in "Name" with "something"
    And I attach the file "test/fixtures/5k.png" to "Attachment"
    And I press "Submit"
    Then I should see "Name: something"
    And I should see an image with a path of "/users/1/attachments?style=original"
    And there should be no file at "/system/attachments/1/original/5k.png"
    And I follow "Download"
    Then I should receive a file "5k.png"
