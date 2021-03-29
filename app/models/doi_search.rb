# frozen_string_literal: true

class DoiSearch
  attr_reader :doi

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
