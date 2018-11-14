# frozen_string_literal: true

class MergeRequest::Pipelines < ActiveRecord::Base
  belongs_to :merge_request, class_name: 'MergeRequest'
  belongs_to :pipeline, class_name: 'Ci::Pipeline'
end
