# frozen_string_literal: true

class ThumbnailUrlService
  def initialize(resource)
    # @resource will be a SolrDocument (containing a Collection or Work),
    # Collection, Work, or WorkVersion
    @resource = resource
  end

  def url
    file_resources.present? ? file_resources.last.file_attacher.url(:thumbnail).presence : nil
  end

  private

    def file_resources
      resource.is_a?(WorkVersion) ? resource.file_resources : work.latest_published_version.file_resources
    end

    def work
      resource.is_a?(SolrDocument) ? solr_doc_to_work(resource) : non_solr_doc_to_work(resource)
    end

    def solr_doc_to_work(solr_doc)
      solr_doc.model == 'Collection' ?
          Collection.find_by(uuid: solr_doc.id).works.first :
          Work.find(resource.work_id)
    end

    def non_solr_doc_to_work(resource)
      resource.is_a?(Collection) ? resource.works.first : resource
    end

    attr_accessor :resource
end
