# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CitationComponent, type: :component do
  let(:component) { described_class.new(work_version, pathway) }
  let(:pathway) { instance_double(WorkDepositPathway, data_and_code?: data_and_code, instrument?: instrument) }
  let(:data_and_code) { true }
  let(:instrument) { false }

  describe 'rendering' do
    context 'when not given a data and code or instrument pathway' do
      let(:data_and_code) { false }
      let(:work_version) { build(:work_version, :published, work: build(:work, work_type: 'article')) }
      let(:citation_component) { render_inline(component) }

      it 'does not render anything' do
        expect(citation_component.css('div.keyline')).to be_empty
      end
    end

    context 'when given a data and code pathway' do
      let(:work_version) {
        build(
          :work_version,
          :published,
          work: build(:work, work_type: 'dataset', doi: '10.26207/123'),
          title: 'Citation Title',
          published_date: '2024-02-16',
          doi: '10.26207/123'
        )
      }
      let(:authorship1) { build(:authorship, given_name: 'Alan', surname: 'Grant') }
      let(:citation_component) { render_inline(component) }

      before { work_version.creators = [authorship1] }

      context 'when there is one creator' do
        let(:expected_citation) { 'Grant, Alan (2024). Citation Title [Data set]. Scholarsphere. https://doi.org/10.26207/123' }

        it 'renders the citation' do
          expect(citation_component.css('div.keyline')).not_to be_empty
          expect(citation_component.text).to include(expected_citation)
        end
      end

      context 'when there are multiple creators' do
        let(:expected_citation) { 'Grant, Alan; Sattler, Ellie; Malcolm, Ian (2024). Citation Title [Data set]. Scholarsphere. https://doi.org/10.26207/123' }
        let(:authorship2) { build(:authorship, given_name: 'Ellie', surname: 'Sattler') }
        let(:authorship3) { build(:authorship, given_name: 'Ian', surname: 'Malcolm') }

        before { work_version.creators << [authorship2, authorship3] }

        it 'renders the citation' do
          expect(citation_component.css('div.keyline')).not_to be_empty
          expect(citation_component.text).to include(expected_citation)
        end
      end
    end

    context 'when given an instrument pathway' do
      let(:work_version) {
        build(
          :work_version,
          :published,
          work: build(:work, work_type: 'instrument', doi: '10.26207/123'),
          title: 'Citation Title',
          published_date: '2024-02-16',
          doi: '10.26207/123'
        )
      }
      let(:authorship1) { build(:authorship, given_name: 'Alan', surname: 'Grant') }
      let(:citation_component) { render_inline(component) }
      let(:data_and_code) { false }
      let(:instrument) { true }

      before { work_version.creators = [authorship1] }

      context 'when there is one creator' do
        let(:expected_citation) { 'Grant, Alan (2024). Citation Title [Data set]. Scholarsphere. https://doi.org/10.26207/123' }

        it 'renders the citation' do
          expect(citation_component.css('div.keyline')).not_to be_empty
          expect(citation_component.text).to include(expected_citation)
        end
      end

      context 'when there are multiple creators' do
        let(:expected_citation) { 'Grant, Alan; Sattler, Ellie; Malcolm, Ian (2024). Citation Title [Data set]. Scholarsphere. https://doi.org/10.26207/123' }
        let(:authorship2) { build(:authorship, given_name: 'Ellie', surname: 'Sattler') }
        let(:authorship3) { build(:authorship, given_name: 'Ian', surname: 'Malcolm') }

        before { work_version.creators << [authorship2, authorship3] }

        it 'renders the instrument citation' do
          expect(citation_component.css('div.keyline')).not_to be_empty
          expect(citation_component.text).to include(expected_citation)
        end
      end
    end
  end
end
