require 'spec_helper'

describe PluginWorker do
  include RepoHelpers

  subject { described_class.new }

  let(:filename) { 'my_plugin.rb' }

  describe '#perform' do
    it 'executes Gitlab::Plugin with expected values' do
      data = { 'event_name' => 'project_create' }

      allow(Gitlab::Plugin).to receive(:execute).with(filename, data).and_return(true)

      expect(subject.perform(filename, data)).to be_truthy
    end
  end
end
