# frozen_string_literal: true

class EmbargoDetailComponent < FilesMessageComponent
  def render?
    work_version.embargoed?
  end

  def heading
    I18n.t('embargo.heading', date: embargo_release_date)
  end

  def i18n_key
    'embargo'
  end

  private

    def embargo_release_date
      work_version.work.embargoed_until.strftime('%Y-%m-%d')
    end
end
