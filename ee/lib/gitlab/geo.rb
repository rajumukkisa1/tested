# frozen_string_literal: true

module Gitlab
  module Geo
    OauthApplicationUndefinedError = Class.new(StandardError)
    GeoNodeNotFoundError = Class.new(StandardError)
    InvalidDecryptionKeyError = Class.new(StandardError)
    InvalidSignatureTimeError = Class.new(StandardError)

    CACHE_KEYS = %i(
      primary_node
      secondary_nodes
      node_enabled
      oauth_application
    ).freeze

    def self.current_node
      self.cache_value(:current_node) { GeoNode.current_node }
    end

    def self.primary_node
      self.cache_value(:primary_node) { GeoNode.primary_node }
    end

    def self.secondary_nodes
      self.cache_value(:secondary_nodes) { GeoNode.secondary_nodes }
    end

    def self.connected?
      Gitlab::Database.postgresql? && GeoNode.connected? && GeoNode.table_exists?
    end

    def self.enabled?
      cache_value(:node_enabled) { GeoNode.exists? }
    end

    def self.primary?
      self.enabled? && self.current_node&.primary?
    end

    def self.secondary?
      self.enabled? && self.current_node&.secondary?
    end

    def self.current_node_enabled?
      # No caching of the enabled! If we cache it and an admin disables
      # this node, an active Geo::RepositorySyncWorker would keep going for up
      # to max run time after the node was disabled.
      Gitlab::Geo.current_node.reload.enabled?
    end

    def self.geo_database_configured?
      Rails.configuration.respond_to?(:geo_database)
    end

    def self.primary_node_configured?
      Gitlab::Geo.primary_node.present?
    end

    def self.secondary_with_primary?
      self.secondary? && self.primary_node_configured?
    end

    def self.license_allows?
      ::License.feature_available?(:geo)
    end

    def self.configure_cron_jobs!
      manager = CronManager.new
      manager.create_watcher!
      manager.execute
    end

    def self.oauth_authentication
      return false unless Gitlab::Geo.secondary?

      self.cache_value(:oauth_application) do
        Gitlab::Geo.current_node.oauth_application || raise(OauthApplicationUndefinedError)
      end
    end

    def self.cache_key_for(key)
      "geo:#{key}:#{Rails.version}"
    end

    def self.cache_value(raw_key, &block)
      return yield unless Gitlab::SafeRequestStore.active?

      key = cache_key_for(raw_key)

      Gitlab::SafeRequestStore.fetch(key) do
        # We need a short expire time as we can't manually expire on a secondary node
        Rails.cache.fetch(key, expires_in: 15.seconds) { yield }
      end
    end

    def self.expire_cache!
      return true unless Gitlab::SafeRequestStore.active?

      CACHE_KEYS.each do |raw_key|
        key = cache_key_for(raw_key)

        Rails.cache.delete(key)
        Gitlab::SafeRequestStore.delete(key)
      end

      true
    end

    def self.generate_access_keys
      # Inspired by S3
      {
        access_key: generate_random_string(20),
        secret_access_key: generate_random_string(40)
      }
    end

    def self.generate_random_string(size)
      # urlsafe_base64 may return a string of size * 4/3
      SecureRandom.urlsafe_base64(size)[0, size]
    end

    def self.repository_verification_enabled?
      feature = ::Feature.get('geo_repository_verification')

      # If the feature has been set, always evaluate
      if ::Feature.persisted?(feature)
        return feature.enabled?
      else
        true
      end
    end
  end
end
