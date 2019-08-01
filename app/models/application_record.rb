# frozen_string_literal: true

class ActiveRecord::Base
  # before_validation
  # after_validation
  # before_save
  # around_save
  # before_create
  # around_create
  # after_create
  # after_save
  after_commit :after_commit_create, on: :create
  # after_rollback

  # before_validation
  # after_validation
  # before_save
  # around_save
  # before_update
  # around_update
  # after_update
  # after_save
  after_commit :after_commit_update, on: :update
  # after_rollback

  # before_destroy
  # around_destroy
  # after_destroy
  after_commit :after_commit_destroy, on: :destroy
  # after_rollback

  private
    def after_commit_create
      name = self.class.name
      attributes = self.attributes
      Rails.logger.debug "created a #{name} with attributes #{attributes}!"

      properties = attributes.merge "object_type" => name
      HeapMiddleware.track "created", properties
    end

    def after_commit_destroy
      name = self.class.name
      attributes = self.attributes
      Rails.logger.debug "destroyed a #{name} with attributes #{attributes}!"

      properties = attributes.merge "object_type" => name
      HeapMiddleware.track "destroyed", properties
    end

    def after_commit_update
      name = self.class.name
      attributes = self.attributes
      Rails.logger.debug "updated a #{name} with attributes #{attributes}!"

      properties = attributes.merge "object_type" => name
      HeapMiddleware.track "updated", properties
    end
end

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
