# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GoogleScholarMetadataComponent, type: :component do
  include Rails.application.routes.url_helpers

  subject(:component) { described_class.new(resource: decorated_resource, policy: mock_policy) }

  let(:decorated_resource) { ResourceDecorator.decorate(resource) }
  let(:mock_policy) { instance_double('WorkVersionPolicy', download?: true) }
  let(:html) { render_inline(component) }

  context 'with multiple downloadable work version pdfs' do
    let(:resource) { create(:work_version, :with_creators, file_resources: [file_resource1, file_resource2]) }
    let(:file_resource1) { create(:file_resource, :pdf) }
    let(:file_resource2) { create(:file_resource, :pdf) }
    let(:file) { resource.file_resources.first }

    it 'renders all the meta tags' do
      expect(html.search('meta[@name="citation_title"]').first['content']).to eq(resource.title)
      expect(html.search('meta[@name="citation_author"]').first['content']).to eq(resource.creators.first.display_name)
      expect(html.search('meta[@name="citation_publication_date"]').first['content']).to eq(Time.zone.now.year.to_s)
      expect(html.search('meta[@name="citation_pdf_url"]').first['content']).to eq(
        resource_download_url(file.id, resource_id: resource.uuid, host: 'test.host')
      )
    end
  end

  context 'when the file resources do not contain a pdf' do
    let(:resource) { create(:work_version, :with_creators, file_resources: [file_resource]) }
    let(:file_resource) { create(:file_resource, :with_processed_image) }
    let(:file) { resource.file_resources.first }

    it 'renders all the meta tags' do
      expect(html.search('meta[@name="citation_title"]').first['content']).to eq(resource.title)
      expect(html.search('meta[@name="citation_author"]').first['content']).to eq(resource.creators.first.display_name)
      expect(html.search('meta[@name="citation_publication_date"]').first['content']).to eq(Time.zone.now.year.to_s)
      expect(html.search('meta[@name="citation_pdf_url"]')).to be_empty
    end
  end

  context 'when the work is not downloadable' do
    let(:resource) { create(:work_version, :with_files, :with_creators) }
    let(:mock_policy) { instance_double('WorkVersionPolicy', download?: false) }

    it 'renders all the meta tags' do
      expect(html.search('meta[@name="citation_title"]').first['content']).to eq(resource.title)
      expect(html.search('meta[@name="citation_author"]').first['content']).to eq(resource.creators.first.display_name)
      expect(html.search('meta[@name="citation_publication_date"]').first['content']).to eq(Time.zone.now.year.to_s)
      expect(html.search('meta[@name="citation_pdf_url"]')).to be_empty
    end
  end

  context 'with a collection' do
    let(:resource) { build(:collection) }

    it { expect(html.content).to be_empty }
  end

  describe '#citation_publication_date' do
    context 'with a missing published date' do
      let(:resource) { build(:work_version, published_date: nil) }

      its(:citation_publication_date) { is_expected.to eq(resource.deposited_at.year) }
    end

    context 'with invalid EDTF' do
      let(:resource) { build(:work_version, published_date: 'Last Thursday') }

      its(:citation_publication_date) { is_expected.to eq(resource.deposited_at.year) }
    end

    context 'with valid EDTF' do
      let(:resource) { build(:work_version, :able_to_be_published) }

      its(:citation_publication_date) { is_expected.to eq Date.edtf(resource.published_date).year }
    end

    context 'with valid EDTF but an uncertain year' do
      let(:resource) { build(:work_version, published_date: '2002?-12') }

      its(:citation_publication_date) { is_expected.to eq(2002) }
    end

    context 'with valid EDTF interval' do
      let(:resource) { build(:work_version, published_date: '2010/2020') }

      its(:citation_publication_date) { is_expected.to eq(Time.zone.now.year) }
    end
  end
end
