# frozen_string_literal: true

class StatusBadgeComponentPreview < ViewComponent::Preview
  def default
    draft = FactoryBot.build_stubbed(:work_version, :draft)
    published = FactoryBot.build_stubbed(:work_version, :published, version_number: 3)
    fancy_version_name = FactoryBot.build_stubbed(:work_version, :published, version_number: 3, version_name: '1.2.3')

    render_with_template(locals: {
                           draft: draft,
                           published: published,
                           fancy_version_name: fancy_version_name
                         })
  end
end
