# frozen_string_literal: true

RSpec.describe QA::Scenario::Test::Instance::Reliable do
  it_behaves_like 'a QA scenario class' do
    let(:tags) { [:reliable] }
  end
end
