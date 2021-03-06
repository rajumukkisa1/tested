# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NotifyHelper do
  include ActionView::Helpers::UrlHelper
  using RSpec::Parameterized::TableSyntax

  describe 'merge_request_reference_link' do
    let(:project) { create(:project) }
    let(:merge_request) { create(:merge_request, source_project: project) }

    it 'returns link to merge request with the text reference' do
      url = "http://test.host/#{project.full_path}/-/merge_requests/#{merge_request.iid}"

      expect(merge_request_reference_link(merge_request)).to eq(reference_link(merge_request, url))
    end
  end

  describe 'issue_reference_link' do
    let(:project) { create(:project) }
    let(:issue) { create(:issue, project: project) }

    it 'returns link to issue with the text reference' do
      url = "http://test.host/#{project.full_path}/-/issues/#{issue.iid}"

      expect(issue_reference_link(issue)).to eq(reference_link(issue, url))
    end
  end

  describe '#invited_to_description' do
    where(:source, :description) do
      build(:project, description: nil) | /Projects are/
      build(:group, description: nil) | /Groups assemble/
      build(:project, description: '_description_') | '_description_'
      build(:group, description: '_description_') | '_description_'
    end

    with_them do
      specify do
        expect(helper.invited_to_description(source)).to match description
      end
    end

    it 'truncates long descriptions', :aggregate_failures do
      description = '_description_ ' * 30
      project = build(:project, description: description)

      result = helper.invited_to_description(project)
      expect(result).not_to match description
      expect(result.length).to be <= 200
    end
  end

  def reference_link(entity, url)
    "<a href=\"#{url}\">#{entity.to_reference}</a>"
  end

  describe '#invited_join_url' do
    let_it_be(:member) { create(:project_member) }

    let(:token) { '_token_' }

    context 'when invite_email_preview_text is enabled', :experiment do
      before do
        stub_experiments(invite_email_preview_text: :control)
      end

      it 'has correct params' do
        expect(helper.invited_join_url(token, member))
          .to eq("http://test.host/-/invites/#{token}?experiment_name=invite_email_preview_text&invite_type=initial_email")
      end
    end

    context 'when invite_email_preview_text is disabled' do
      before do
        stub_feature_flags(invite_email_preview_text: false)
      end

      it 'has correct params' do
        expect(helper.invited_join_url(token, member)).to eq("http://test.host/-/invites/#{token}?invite_type=initial_email")
      end
    end
  end
end
