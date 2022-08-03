# frozen_string_literal: true

require 'rails_helper'

# @note this class is an abstract base, so this test implements a couple
# subclasses to test various scenarios

RSpec.describe WorkHistories::PaperTrailChangeBaseComponent, type: :component do
  let(:user) { build_stubbed :user }
  let(:paper_trail_version) { instance_spy('PaperTrail::Version', item_type: 'ExpectedItemType') }

  before do
    no_item_type_class = Class.new(described_class)
    stub_const('NoItemType', no_item_type_class)

    has_item_type_class = Class.new(described_class) do
      def expected_item_type
        'ExpectedItemType'
      end
    end
    stub_const('HasItemType', has_item_type_class)
  end

  describe '#initialize' do
    context 'when the subclass does not implement #expected_item_type' do
      it do
        expect {
          NoItemType.new(user: user, paper_trail_version: paper_trail_version)
        }.to raise_error(NotImplementedError)
      end
    end

    context 'when the subclass does implement #expected_item_type' do
      it 'requires paper_trail_version to apply to the specified class' do
        expect {
          allow(paper_trail_version).to receive(:item_type).and_return 'DifferentClass'
          HasItemType.new(
            user: user,
            paper_trail_version: paper_trail_version
          )
        }.to raise_error(ArgumentError)

        expect {
          allow(paper_trail_version).to receive(:item_type).and_return 'ExpectedItemType'
          HasItemType.new(
            user: user,
            paper_trail_version: paper_trail_version
          )
        }.not_to raise_error
      end
    end
  end

  describe '#render?' do
    subject { component.render? }

    let(:component) { HasItemType.new(user: user, paper_trail_version: paper_trail_version) }

    context 'when the PaperTrail::Version has changed_by_system = true' do
      before { allow(paper_trail_version).to receive(:changed_by_system).and_return(true) }

      it { is_expected.to be false }
    end

    context 'when the PaperTrail::Version has changed_by_system = false' do
      before { allow(paper_trail_version).to receive(:changed_by_system).and_return(false) }

      it { is_expected.to be true }
    end
  end

  describe '#i18n_key' do
    context 'when the subclass does not implement #i18n_key' do
      it do
        expect {
          HasItemType.new(user: user, paper_trail_version: paper_trail_version)
            .send(:i18n_key)
        }.to raise_error(NotImplementedError).with_message(/Implement #i18n_key/)
      end
    end
  end
end
