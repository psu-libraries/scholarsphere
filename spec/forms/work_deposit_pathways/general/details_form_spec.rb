# frozen_string_literal: true

require 'rails_helper'
require_relative '../_shared_examples_for_details_form'

RSpec.describe WorkDepositPathway::General::DetailsForm, type: :model do
  subject(:form) { described_class.new(wv) }

  let(:wv) {
    instance_double(
      WorkVersion,
      attributes: {
        'description' => 'test description',
        'published_date' => '2024',
        'subtitle' => 'test subtitle',
        'publisher_statement' => 'test publisher_statement',
        'keyword' => 'test keyword',
        'publisher' => 'test publisher',
        'identifier' => 'test identifier',
        'related_url' => 'test related_url',
        'subject' => 'test subject',
        'language' => 'test language',
        'based_near' => 'test location',
        'source' => 'test source',
        'version_name' => '1.0.0'
      },
      'indexing_source=': nil,
      'update_doi=': nil
    )
  }

  it_behaves_like 'a work deposit pathway details form'

  it { is_expected.to delegate_method(:form_partial).to(:work_version) }

  it { is_expected.to allow_value(nil).for(:version_name) }
  it { is_expected.to allow_value('').for(:version_name) }
  it { is_expected.to allow_value('1.0.1').for(:version_name) }
  it { is_expected.to allow_value('1.2.3-beta').for(:version_name) }
  it { is_expected.not_to allow_value('1').for(:version_name) }
  it { is_expected.not_to allow_value('1.0').for(:version_name) }
  it { is_expected.not_to allow_value('v1').for(:version_name) }

  describe '.form_fields' do
    it "returns a frozen array of the names of the form's fields" do
      expect(described_class.form_fields).to eq %w{
        description
        published_date
        subtitle
        publisher_statement
        keyword
        publisher
        identifier
        related_url
        subject
        language
        based_near
        source
        version_name
      }

      expect(described_class.form_fields).to be_frozen
    end
  end

  describe 'attribute initialization' do
    it "sets the form attributes correctly from the given object's attributes" do
      expect(form).to have_attributes(
        {
          description: 'test description',
          published_date: '2024',
          subtitle: 'test subtitle',
          publisher_statement: 'test publisher_statement',
          keyword: 'test keyword',
          publisher: 'test publisher',
          identifier: 'test identifier',
          related_url: 'test related_url',
          subject: 'test subject',
          language: 'test language',
          based_near: 'test location',
          source: 'test source',
          version_name: '1.0.0'
        }
      )
    end
  end

  describe '#save' do
    let(:context) { double }

    before do
      allow(wv).to receive(:save).with(context: context).and_return true
      allow(wv).to receive(:attributes=)
    end

    context 'when the form is valid' do
      it "assigns the form's attributes to the form's work version" do
        form.save(context: context)
        expect(wv).to have_received(:attributes=).with(form.attributes)
      end

      it "saves the form's work version" do
        form.save(context: context)
        expect(wv).to have_received(:save).with(context: context)
      end

      context 'when the work version saves successfully' do
        it 'returns true' do
          expect(form.save(context: context)).to eq true
        end
      end
    end

    context 'when the form is not valid' do
      before { form.description = nil }

      it 'returns nil' do
        expect(form.save(context: context)).to be_nil
      end

      it 'does not persist the form data' do
        form.save(context: context)
        expect(wv).not_to have_received(:save)
      end

      it 'sets errors on the form' do
        form.save(context: context)
        expect(form.errors[:description]).not_to be_empty
      end
    end
  end
end
