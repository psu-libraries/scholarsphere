# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OpenAccessVersion::OawPermissionsClient do
  subject(:client) { described_class.new }

  describe '#map_licence' do
    it 'maps cc-by variants to rights[0]' do
      expect(client.send(:map_licence, 'cc-by')).to eq('https://creativecommons.org/licenses/by/4.0/')
      expect(client.send(:map_licence, 'cc-by 3.0')).to eq('https://creativecommons.org/licenses/by/4.0/')
      expect(client.send(:map_licence, 'cc-by 4.0')).to eq('https://creativecommons.org/licenses/by/4.0/')
    end

    it 'maps cc-by-nc to rights[2]' do
      expect(client.send(:map_licence, 'cc-by-nc')).to eq('https://creativecommons.org/licenses/by-nc/4.0/')
    end

    it 'maps cc-by-nc-nd to rights[4]' do
      expect(client.send(:map_licence, 'cc-by-nc-nd')).to eq('https://creativecommons.org/licenses/by-nc-nd/4.0/')
    end

    it 'maps cc-by-nc-sa to rights[5]' do
      expect(client.send(:map_licence, 'cc-by-nc-sa')).to eq('https://creativecommons.org/licenses/by-nc-sa/4.0/')
    end

    it 'maps cc0 to rights[6]' do
      expect(client.send(:map_licence, 'cc0')).to eq('http://creativecommons.org/publicdomain/zero/1.0/')
    end

    it 'maps other (non-commercial) to rights[11]' do
      expect(client.send(:map_licence, 'other (non-commercial)')).to eq('https://rightsstatements.org/page/InC/1.0/')
    end

    it 'maps unclear to rights[11]' do
      expect(client.send(:map_licence, 'unclear')).to eq('https://rightsstatements.org/page/InC/1.0/')
    end

    it 'maps other-closed variants to rights[11]' do
      expect(client.send(:map_licence, 'other-closed')).to eq('https://rightsstatements.org/page/InC/1.0/')
      expect(client.send(:map_licence, 'Other-Closed by Publisher')).to eq('https://rightsstatements.org/page/InC/1.0/')
    end

    it 'maps none variants to rights[11]' do
      expect(client.send(:map_licence, 'none')).to eq('https://rightsstatements.org/page/InC/1.0/')
      expect(client.send(:map_licence, 'NONE SPECIFIED')).to eq('https://rightsstatements.org/page/InC/1.0/')
    end

    it 'returns nil for nil input' do
      expect(client.send(:map_licence, nil)).to be_nil
    end

    it 'returns nil for unknown values' do
      expect(client.send(:map_licence, 'cc-by-sa')).to be_nil
    end
  end

  describe '#rights' do
    it 'uses WorkVersion::Licenses.options_for_select_box values' do
      expect(client.send(:rights)).to eq(WorkVersion::Licenses.options_for_select_box.pluck(1))
    end
  end
end
