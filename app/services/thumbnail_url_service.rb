# frozen_string_literal: true

class ThumbnailUrlService
  def initialize(resource)
    # @resource could be a SolrDocument or SolrDocumentAdapterDecorator (containing a Collection or Work),
    # Collection, Work, WorkVersion, CollectionDecorator, WorkDecorator, or WorkVersionDecorator
    @resource = resource
  end

  def url
    file_resources.present? ? file_resources.last.file_attacher.url(:thumbnail).presence : nil
  end

  private

    def file_resources
      resource.class.to_s.include?('WorkVersion') ? resource.file_resources : work&.latest_published_version&.file_resources
    end

    def work
      resource.class.to_s.include?('SolrDocument') ? solr_doc_to_work(resource) : non_solr_doc_to_work(resource)
    end

    def solr_doc_to_work(solr_doc)
      solr_doc.model.include?('Collection') ?
          Collection.find_by(uuid: solr_doc.id).works.first :
          Work.find(resource.work_id)
    end

    def non_solr_doc_to_work(resource)
      resource.class.to_s.include?('Collection') ? resource.works.first : resource
    end

    attr_accessor :resource
end
