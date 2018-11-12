# frozen_string_literal: true

class PipelineScheduleWorker
  include ApplicationWorker
  include CronjobQueue

  # rubocop: disable CodeReuse/ActiveRecord
  def perform
    Ci::PipelineSchedule.active.where("next_run_at < ?", Time.now)
      .preload(:owner, :project).find_each do |schedule|
      begin
        pipeline = Ci::CreatePipelineService.new(schedule.project,
                                                 schedule.owner,
                                                 ref: schedule.ref)
          .execute(:schedule, ignore_skip_ci: true, save_on_errors: false, schedule: schedule).tap do
            Ci::CreateMergeRequestPipelinesService
              .new(schedule.project, schedule.owner, ref: schedule.ref)
              .execute(:schedule, ignore_skip_ci: true, save_on_errors: false, schedule: schedule)
          end

        schedule.deactivate! unless pipeline.persisted?
      rescue => e
        Rails.logger.error "#{schedule.id}: Failed to create a scheduled pipeline: #{e.message}"
      ensure
        schedule.schedule_next_run!
      end
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
