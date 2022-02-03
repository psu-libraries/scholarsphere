# frozen_string_literal: true

class ThumbnailUrlService
  def initialize(resource)
    @resource = resource
  end

  def url
    file_resources.present? ? file_resources.last.file_attacher.url(:thumbnail).presence : nil
  end

  private

    def file_resources
      work.latest_published_version.file_resources
    end

    def work
      resource.is_a?(SolrDocument) ? solr_doc_to_work(resource) : collection_to_work(resource)
    end

    def collection_to_work(resource)
      resource.is_a?(Collection) ? resource.works.first.work : resource.work
    end

    def solr_doc_to_work(solr_doc)
      solr_doc["model_ssi"] == 'Collection' ?
          Collection.find_by(uuid: solr_doc.id).works.first.work :
          Work.find(resource.work_id)
    end

    attr_accessor :resource
end
