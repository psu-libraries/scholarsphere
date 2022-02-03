# frozen_string_literal: true

# Presents one of our ActiveRecord Resources as a Solr document with the goal of
# sharing view partials.
class SolrDocumentAdapterDecorator < SimpleDelegator
  def id
    uuid
  end

  def itemtype
    'http://schema.org/Thing'
  end

  def model
    to_model.class.to_s
  end
end
