# frozen_string_literal: true

module Releases
  class DestroyService < BaseService
    include Gitlab::Utils::StrongMemoize

    def execute
      return error('Tag does not exist', 404) unless existing_tag
      return error('Release does not exist', 404) unless release
      return error('Access Denied', 403) unless allowed?

      if release.destroy
        success(tag: existing_tag, release: release)
      else
        error(release.errors.messages || '400 Bad request', 400)
      end
    end

    private

    def allowed?
      Ability.allowed?(current_user, :destroy_release, release)
    end

    def release
      strong_memoize(:release) do
        project.releases.find_by_tag(tag_name)
      end
    end

    def existing_tag
      strong_memoize(:existing_tag) do
        project.repository.find_tag(tag_name)
      end
    end
  end
end
