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
    it 'filters all values returned by #fields_with_dois and returns canonical DOIs' do
      expect(instance.all_dois).to match_array(['doi:10.18113/3ln3-2by1',
                                                'doi:10.1515/pol-2020-2011',
                                                'doi:10.1007/s10570-013-0029-x'])
    end
  end
end
