# frozen_string_literal: true

module Gitlab
  module ImportExport
    module AfterExportStrategies
      class BaseAfterExportStrategy
        extend Gitlab::ImportExport::CommandLineUtil
        include ActiveModel::Validations
        extend Forwardable

        StrategyError = Class.new(StandardError)

        private

        attr_reader :project, :current_user, :lock_file

        public

        def initialize(attributes = {})
          @options = OpenStruct.new(attributes)

          self.class.instance_eval do
            def_delegators :@options, *attributes.keys
          end
        end

        def execute(current_user, project)
          @project = project

          ensure_export_ready!
          ensure_lock_files_path!
          @lock_file = File.join(lock_files_path, SecureRandom.hex)

          return unless @project.export_status == :finished

          @current_user = current_user

          if invalid?
            log_validation_errors

            return
          end

          create_or_update_after_export_lock
          strategy_execute

          true
        rescue => e
          project.import_export_shared.error(e)
          false
        ensure
          delete_after_export_lock
        end

        def to_json(options = {})
          @options.to_h.merge!(klass: self.class.name).to_json
        end

        def ensure_export_ready!
          raise StrategyError unless project.export_path || export_file_exists?
        end

        def ensure_lock_files_path!
          FileUtils.mkdir_p(lock_files_path) unless Dir.exist?(lock_files_path)
        end

        def lock_files_path
          project.import_export_shared.lock_files_path
        end

        def locks_present?
          project.import_export_shared.locks_present?
        end

        protected

        def strategy_execute
          raise NotImplementedError
        end

        private

        def create_or_update_after_export_lock
          FileUtils.touch(lock_file)
        end

        def delete_after_export_lock
          FileUtils.rm(lock_file) if lock_file.present? && File.exist?(lock_file)
        end

        def log_validation_errors
          errors.full_messages.each { |msg| project.import_export_shared.add_error_message(msg) }
        end

        def export_file_exists?
          project.export_file_exists?
        end
      end
    end
  end
end
