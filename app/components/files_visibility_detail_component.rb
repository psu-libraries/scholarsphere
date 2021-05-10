# frozen_string_literal: true

class FilesVisibilityDetailComponent < FilesMessageComponent
  def render?
    embargoed? || unauthorized?
  end

  def heading
    if embargoed?
      I18n.t('files_message.embargo.heading', date: embargo_release_date)
    elsif unauthorized?
      I18n.t('files_message.unauthorized.heading')
    end
  end

  def i18n_key
    if unauthorized? && embargoed?
      'embargo_unauthorized'
    elsif embargoed?
      'embargo'
    elsif unauthorized?
      'unauthorized'
    end
  end

  private

    def embargoed?
      work_version.embargoed?
    end

    def unauthorized?
      work_version.work.visibility == Permissions::Visibility::AUTHORIZED && !download?
    end

    def embargo_release_date
      work_version.work.embargoed_until.strftime('%Y-%m-%d')
    end
end
