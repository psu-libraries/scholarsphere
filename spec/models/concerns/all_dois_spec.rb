# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AllDois do
  subject(:instance) { TestModel.new }

  before(:all) do
    class TestModel
      # @note This is to fake ActiveRecord integration
      def self.validates(*args)
        # noop
      end

      include AllDois
      fields_with_dois :doi, :identifier, :other

      def doi
        'doi:10.18113/3ln3-2by1'
      end

      def identifier
        ['https://doi.org/10.1515/pol-2020-2011',
         '10.1007/s10570-013-0029-x',
         'http://google.com',
         '12',
         34,
         nil,
         '',
         {}]
      end

      def other
        'doi:10.1515/pol-2020-2011' # A duplicate of one in #identifier
      end
    end
  end

  after(:all) do
    ActiveSupport::Dependencies.remove_constant('TestModel')
  end

  describe '#all_dois' do
    context 'when resource is not a WorkVersion' do
      it 'filters all values returned by #fields_with_dois and returns canonical DOIs' do
        expect(instance.all_dois).to match_array(['doi:10.18113/3ln3-2by1',
                                                  'doi:10.1515/pol-2020-2011',
                                                  'doi:10.1007/s10570-013-0029-x'])
      end
    end

    context 'when resource is a WorkVersion' do
      subject(:instance) { work.versions.last }

      let!(:work) { create :work, versions_count: 2, has_draft: false }

      before do
        instance.update doi: '10.18113/s9k3-x5gh'
      end

      context 'when WorkVersion is not the lastest published version' do
        before do
          instance.update aasm_state: 'draft'
        end

        it 'returns an empty array' do
          expect(instance.all_dois).to eq []
        end
      end

      context 'when WorkVersion is the lastest published version' do
        context "when WorkVersion's Work has a DOI" do
          before do
            instance.work.doi = '10.18113/44md-dj4'
          end

          it 'returns an empty array' do
            expect(instance.all_dois).to eq []
          end
        end

        context "when WorkVersion's Work does not have a DOI" do
          it 'filters all values returned by #fields_with_dois and returns canonical DOIs' do
            expect(instance.all_dois).to match_array(['doi:10.18113/s9k3-x5gh'])
          end
        end
      end
    end
  end
end
