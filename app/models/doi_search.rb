# frozen_string_literal: true

class DoiSearch
  attr_reader :doi

  # Finds every document in Solr that references a DOI.
  #
  # @returns Hash{String=>Set<String>} where the key is the DOI, and the value
  # is a collection of uuids corresponding to the resources that mention that DOI
  #
  # Technically the values are Set objects, but for our purposes they behave
  # just like any other collection, and are serialized to JSON like an arrray
  def self.all
    # Use of Set here instead of array provides automatic deduplication if a
    # DOI happens to reference the same document twice
    uuids_by_doi = Hash.new { |hash, doi| hash[doi] = Set.new }

    Blacklight
      .default_index
      .search(
        q: %(all_dois_ssim:*),
        fl: ['id', 'all_dois_ssim'],
        rows: 1_000_000_000
      )
      .docs
      .each do |solr_doc|                       # Loop through all docs
        solr_doc['all_dois_ssim'].each do |doi| # Loop through all dois in that doc
          uuids_by_doi[doi].add(solr_doc.id)    # Add doc to each doi's Set
        end
      end

    uuids_by_doi
  end

  def initialize(doi:)
    @doi = Doi.new(doi)
  end

  # @returns an array of uuids for the matching resources
  def results
    return [] unless doi.valid?

    doi_query = escape(doi.to_s)

    Blacklight
      .default_index
      .search(
        q: %(all_dois_ssim:"#{doi_query}"),
        fl: ['id'],
        rows: max_documents
      )
      .docs
      .map(&:id)
  end

  private

    def max_documents
      1_000
    end

    def escape(value)
      RSolr.solr_escape(value)
    end
end
