# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::DependencyProxy, api: true do
  include ExclusiveLeaseHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:blob) { create(:dependency_proxy_blob )}
  let_it_be(:group, reload: true) { blob.group }

  before do
    group.add_owner(user)
    stub_config(dependency_proxy: { enabled: true })
    stub_last_activity_update
  end

  describe 'DELETE /groups/:id/dependency_proxy/cache' do
    subject { delete api("/groups/#{group_id}/dependency_proxy/cache", user) }

    shared_examples 'responding to purge requests' do
      context 'with feature available and enabled' do
        let_it_be(:lease_key) { "dependency_proxy:delete_group_blobs:#{group.id}" }

        context 'an admin user' do
          it 'deletes the blobs and returns no content' do
            stub_exclusive_lease(lease_key, timeout: 1.hour)
            expect(PurgeDependencyProxyCacheWorker).to receive(:perform_async)

            subject

            expect(response).to have_gitlab_http_status(:accepted)
            expect(response.body).to eq('202')
          end

          context 'called multiple times in one hour', :clean_gitlab_redis_shared_state do
            it 'returns 409 with an error message' do
              stub_exclusive_lease_taken(lease_key, timeout: 1.hour)

              subject

              expect(response).to have_gitlab_http_status(:conflict)
              expect(response.body).to include('This request has already been made.')
            end

            it 'executes service only for the first time' do
              expect(PurgeDependencyProxyCacheWorker).to receive(:perform_async).once

              2.times { subject }
            end
          end
        end

        context 'a non-admin' do
          let(:user) { create(:user) }

          before do
            group.add_maintainer(user)
          end

          it_behaves_like 'returning response status', :forbidden
        end
      end

      context 'depencency proxy is not enabled in the config' do
        before do
          stub_config(dependency_proxy: { enabled: false })
        end

        it_behaves_like 'returning response status', :not_found
      end
    end

    context 'with a group id' do
      let(:group_id) { group.id }

      it_behaves_like 'responding to purge requests'
    end

    context 'with an url encoded group id' do
      let(:group_id) { ERB::Util.url_encode(group.full_path) }

      it_behaves_like 'responding to purge requests'
    end
  end
end
