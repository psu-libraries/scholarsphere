# frozen_string_literal: true

class PublishedDateSchema < BaseSchema
  def document
    return {} unless resource.respond_to?(:published_date)

    published_date = resource.send(:published_date)

    return {} unless EdtfDate.valid?(published_date)

    date_range = EdtfDate::SolrDateRangeFormatter.format(published_date)

    {
      published_date_dtrsi: date_range
    }
  end
end
