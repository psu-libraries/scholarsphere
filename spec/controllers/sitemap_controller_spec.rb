# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SitemapController do
  let(:sitemap) { described_class.new }

  describe 'GET #index' do
    it 'returns a list of each hexadecimal character' do
      expect(sitemap.index).to eq([*('a'..'f'), *('0'..'9')])
    end
  end

  describe 'GET #show' do
    let(:public_work) { build(:work, has_draft: false) }
    let(:psu_work) { build(:work, :with_authorized_access, has_draft: false) }
    let(:private_work) { build(:work, :with_private_access, has_draft: false) }
    let(:collection) { build(:collection, :with_published_works) }

    let(:ids_0) { Array.new(4) { "0#{Faker::Number.number(digits: 7)}" } }
    let(:ids_1) { Array.new(4) { "1#{Faker::Number.number(digits: 7)}" } }

    let(:found_ids) { ids_0.take(3) }
    let(:other_ids) { ids_1.push(ids_0.last) }

    before do
      # Index each resource into Solr with one of the random ids we've created, but note that order is important because
      # we should *not* find the private_work.
      [public_work, psu_work, collection, private_work].each_with_index do |resource, index|
        document = resource.to_solr
        Blacklight.default_index.connection.add(document.merge(id: ids_0[index], uuid_ssi: ids_0[index]))
        Blacklight.default_index.connection.add(document.merge(id: ids_1[index], uuid_ssi: ids_1[index]))
      end
      Blacklight.default_index.connection.commit
    end

    render_views

    it 'renders appropriate XML in the show view' do
      get :show, params: { id: 0 }, format: 'xml'
      found_ids.each do |id|
        expect(response.body).to include "<loc>http://test.host/resources/#{id}</loc>"
      end
      other_ids.each do |id|
        expect(response.body).not_to include "<loc>http://test.host/resources/#{id}</loc>"
      end
    end
  end
end
