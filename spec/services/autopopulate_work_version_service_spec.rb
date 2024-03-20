# frozen_string_literal: true

require 'rails_helper'
require 'support/vcr'

RSpec.describe AutopopulateWorkVersionService do
  let(:service) { described_class.new(work_version, doi) }
  let(:work) { create :work }
  let(:work_version) { work.latest_version }
  let(:doi) { 'https://doi.org/10.1038/abcdefg1234567' }
  let(:rmd_publication) do 
    contributor = Struct.new(:first_name, :middle_name, :last_name, :psu_user_id, :position)
    contributors = [contributor.new("Anne", "Example", "Contributor", "abc1234", 1), 
                    contributor.new("Joe", "Fakeman", "Person", "def1234", 2)]
    double(
      RmdPublication,
      title: "A Scholarly Research Article",
      secondary_title: "A Comparative Analysis",
      abstract: "A summary of the research",
      publisher: "A Publishing Company",
      preferred_open_access_url: "https://example.org/articles/article-123.pdf",
      published_on: "2010-12-05",
      supplementary_url: "https://blog.com/post",
      contributors: contributors,
      tags: ["A Topic", "Another Topic"]
    )
  end
  let!(:existing_actor) { create :actor, psu_id: "def1234", display_name: "Existing Actor"}

  before do
    allow(service).to receive(:rmd_pub).and_return(rmd_publication)
  end

  describe '#call' do
    it 'updates the work_version with the attributes from the found RmdPublication' do
      expect { service.call }.to change { Actor.count }.by 1
      expect(work_version.title).to eq "A Scholarly Research Article"
      expect(work_version.subtitle).to eq "A Comparative Analysis"
      expect(work_version.description).to eq "A summary of the research"
      expect(work_version.publisher).to eq ["A Publishing Company"]
      expect(work_version.related_url).to eq ["https://example.org/articles/article-123.pdf"]
      expect(work_version.published_date).to eq "2010-12-05"
      expect(work_version.creators.count).to eq 2
      expect(work_version.creators.first.display_name).to eq "Anne Example Contributor"
      expect(work_version.creators.first.email).to eq "abc1234@psu.edu"
      expect(work_version.creators.first.actor.display_name).to eq "Anne Example Contributor"
      expect(work_version.creators.second.display_name).to eq "Joe Fakeman Person"
      expect(work_version.creators.second.email).to eq "def1234@psu.edu"
      expect(work_version.creators.second.actor.display_name).to eq "Existing Actor"
      expect(work_version.keyword).to eq ["A Topic", "Another Topic"]
      expect(work_version.identifier).to eq [doi]
    end
  end
end
