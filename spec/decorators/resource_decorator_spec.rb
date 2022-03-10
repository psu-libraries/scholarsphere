# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResourceDecorator do
  subject(:decorator) { described_class.new(resource) }

  it 'extends SimpleDelegator' do
    expect(described_class).to be < SimpleDelegator
  end

  describe '::decorate' do
    subject { described_class.decorate(resource) }

    context 'when given a WorkVersion' do
      let(:resource) { WorkVersion.new }

      it { is_expected.to be_a WorkVersionDecorator }
    end

    context 'when given a Work' do
      let(:resource) { Work.new }

      it { is_expected.to be_a WorkDecorator }
    end

    context 'when given a Collection' do
      let(:resource) { Collection.new }

      it { is_expected.to be_a CollectionDecorator }
    end

    context 'when given some other model' do
      specify { expect { described_class.decorate(User.new) }.to raise_error(ArgumentError) }
    end
  end

  describe '#to_model' do
    let(:resource) { build(:work) }

    it 'returns the original object' do
      expect(decorator.to_model.object_id).to eq resource.object_id
    end

    context 'when there are multiple ResourceDecorators wrapped around each other' do
      it 'returns the ActiveRecord under all the nesting' do
        decorator = described_class.new(
          described_class.new(
            described_class.new(resource)
          )
        )
        expect(decorator.to_model.object_id).to eq resource.object_id
      end
    end
  end

  describe '#partial_name' do
    context 'with a work' do
      let(:resource) { build(:work) }

      its(:partial_name) { is_expected.to eq('work') }
    end

    context 'with a work version' do
      let(:resource) { build(:work_version) }

      its(:partial_name) { is_expected.to eq('work_version') }
    end

    context 'with a collection' do
      let(:resource) { build(:collection) }

      its(:partial_name) { is_expected.to eq('collection') }
    end
  end

  describe '#display_work_type' do
    context 'with a work' do
      let(:resource) { build(:work) }

      its(:display_work_type) { is_expected.to eq('Dataset') }
    end

    context 'with a work version' do
      let(:resource) { build(:work_version) }

      its(:display_work_type) { is_expected.to eq('Dataset') }
    end

    context 'with a collection' do
      let(:resource) { build(:collection) }

      its(:display_work_type) { is_expected.to eq('Collection') }
    end
  end

  describe '#display_published_date' do
    before do
      allow(EdtfDate).to receive(:humanize).with('resource_published_date')
        .and_return(:delegated_to_edtf_humanize)
    end

    context 'with a work' do
      let(:resource) { build(:work) }

      its(:display_published_date) { is_expected.to be_nil }
    end

    context 'with a work version' do
      let(:resource) { build(:work_version, published_date: 'resource_published_date') }

      its(:display_published_date) { is_expected.to eq(:delegated_to_edtf_humanize) }
    end

    context 'with a collection' do
      let(:resource) { build(:collection, published_date: 'resource_published_date') }

      before do
        allow(EdtfDate).to receive(:humanize).with(resource.published_date)
          .and_return(:delegated_to_edtf_humanize)
      end

      its(:display_published_date) { is_expected.to eq(:delegated_to_edtf_humanize) }
    end
  end

  describe '#display_doi' do
    let(:resource) { build_stubbed :work }

    before do
      allow(MintingStatusDoiComponent).to receive(:new).and_return(:minting_status_doi_component)
    end

    context 'when the resource has a doi' do
      before { resource.doi = 'abc/123' }

      it 'returns a new doi component, initialized with #resource_with_doi' do
        expect(decorator.display_doi).to eq :minting_status_doi_component
        expect(MintingStatusDoiComponent).to have_received(:new).with(resource: resource)
      end
    end

    context 'when the resource does not have a doi' do
      before { resource.doi = nil }

      it 'returns nil' do
        expect(decorator.display_doi).to be_nil
      end
    end
  end

  describe '#visibility_badge' do
    context 'with a WorkVersion' do
      let(:resource) { build_stubbed :work_version }

      its(:visibility_badge) { is_expected.to be_a(VisibilityBadgeComponent) }
    end

    context 'with a Work' do
      let(:resource) { build_stubbed :work }

      its(:visibility_badge) { is_expected.to be_a(VisibilityBadgeComponent) }
    end
  end

  describe '#first_creators' do
    context 'when there are only creators' do
      let(:resource) { build_stubbed :work_version, :with_creators, creator_count: 3 }

      its(:first_creators) { is_expected.to eq(resource.creators) }
    end

    context 'when there are more than three creators' do
      let(:resource) { build_stubbed :work_version, :with_creators, creator_count: 4 }

      its(:first_creators) { is_expected.to eq(resource.creators.take(3) + ['&hellip;']) }
    end
  end

  describe '#description_html' do
    subject(:description_html) { decorator.description_html }

    let(:parsed) { Nokogiri::HTML(description_html) }
    let(:resource) { instance_spy('WorkVersion') }

    context 'when description_html contains markdown' do
      before do
        allow(resource).to receive(:description).and_return(<<-MARKDOWN.strip_heredoc)
          This is my first paragraph, which is *emphasized*.

          This is my second paragraph with has a [link](https://scholarsphere.psu.edu)

          And this is my third paragraph which has an autolink to https://google.com

          This paragraph has <h1>sneaky html</h1>
        MARKDOWN

        allow(resource).to receive(:publisher_statement).and_return(<<-MARKDOWN.strip_heredoc)
          ## Publisher's Statement

          Here's some important stuff that you need to know.
        MARKDOWN
      end

      it 'renders the description into markdown' do
        expect(description_html).to be_html_safe

        expect(parsed.css('p').length).to eq 5

        parsed.css('p').first.tap do |first_paragraph|
          expect(first_paragraph.css('em').text).to eq 'emphasized'
        end
      end

      it 'supports explicit links' do
        parsed.css('p')[1].tap do |second_paragraph|
          expect(second_paragraph.css('a').text).to eq 'link'
          expect(second_paragraph.css('a')[0]['href']).to eq 'https://scholarsphere.psu.edu'
        end
      end

      it 'supports autolinks' do
        parsed.css('p')[2].tap do |third_paragraph|
          expect(third_paragraph.css('a').text).to eq 'https://google.com'
          expect(third_paragraph.css('a')[0]['href']).to eq 'https://google.com'
        end
      end

      it 'does not allow html' do
        parsed.css('p')[3].tap do |fourth_paragraph|
          expect(fourth_paragraph.css('h1').text).to be_empty
        end
      end

      context 'when given nil' do
        before do
          allow(resource).to receive(:description).and_return(nil)
          allow(resource).to receive(:publisher_statement).and_return(nil)
        end

        it { is_expected.to eq '' }
      end

      context 'when given something that explodes' do
        before do
          allow(Redcarpet::Markdown).to receive(:new).and_raise
        end

        let(:combined_description) do
          [resource.description, resource.publisher_statement].join("\n\r")
        end

        it 'traps the error and returns the original string' do
          expect(description_html).to eq(combined_description)
          expect(description_html).not_to be_html_safe
        end
      end
    end

    context 'when description_html does not contain markdown' do
      before do
        allow(resource).to receive(:description).and_return('Description.')
        allow(resource).to receive(:publisher_statement).and_return('Publisher Statement')
      end

      it 'renders the description into html' do
        expect(description_html).to be_html_safe

        expect(parsed.css('p').length).to eq 2

        parsed.css('p').last.tap do |last_paragraph|
          expect(last_paragraph.text).to eq 'Publisher Statement'
        end
      end
    end
  end

  describe '#description_plain_text' do
    subject(:description_plain_text) { decorator.description_plain_text }

    let(:resource) { instance_spy('WorkVersion') }

    before do
      allow(resource).to receive(:description).and_return(
        'This *is* _marked_ [down](http://psu.edu)'
      )
      allow(resource).to receive(:publisher_statement).and_return(
        '##Publisher Statement'
      )
    end

    it 'returns plain text, without any markdown or html formatting' do
      expect(description_plain_text).to match(/This is marked down\n\nPublisher Statement/)
      expect(description_plain_text).not_to be_html_safe
    end

    context 'when given nil' do
      before do
        allow(resource).to receive(:description).and_return(nil)
        allow(resource).to receive(:publisher_statement).and_return(nil)
      end

      it { is_expected.to eq '' }
    end
  end
end
