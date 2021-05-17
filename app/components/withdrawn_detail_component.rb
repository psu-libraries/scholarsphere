# frozen_string_literal: true

class WithdrawnDetailComponent < FilesMessageComponent
  def render?
    work_version.withdrawn?
  end

  def heading
    I18n.t('files_message.withdrawn.heading')
  end

  def i18n_key
    'withdrawn'
  end
end
