# frozen_string_literal: true

module Types
  module PermissionTypes
    class Group < BasePermissionType
      graphql_name 'GroupPermissions'

      abilities :read_group, :create_projects
    end
  end
end
