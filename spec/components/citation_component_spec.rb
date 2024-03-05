# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CitationComponent, type: :component do
  describe 'rendering' do
    context 'when the work is an article' do
      let(:work_version) { create :work_version, :published, work: create(:work, work_type: 'article') }
      let(:citation_component) { render_inline(described_class.new(work_version)) }

      it 'does not render anything' do
        expect(citation_component.css('div.keyline')).to be_empty
      end
    end

    context 'when the work is a dataset' do
      let(:work_version) { create :work_version,
                                  :published,
                                  work: create(:work, work_type: 'dataset', doi: '10.26207/123'),
                                  title: 'Citation Title',
                                  published_date: '2024-02-16',
                                  doi: '10.26207/123' }
      let(:authorship1) { create :authorship, given_name: 'Alan', surname: 'Grant' }
      let(:citation_component) { render_inline(described_class.new(work_version)) }

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
        let(:authorship2) { create :authorship, given_name: 'Ellie', surname: 'Sattler' }
        let(:authorship3) { create :authorship, given_name: 'Ian', surname: 'Malcolm' }

        before { work_version.creators << [authorship2, authorship3] }

        it 'renders the citation' do
          expect(citation_component.css('div.keyline')).not_to be_empty
          expect(citation_component.text).to include(expected_citation)
        end
      end
    end
  end
end
