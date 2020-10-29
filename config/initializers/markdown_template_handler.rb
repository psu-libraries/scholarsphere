# frozen_string_literal: true

class MarkdownHandler
  def self.call(_template, source)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)

    new_source = markdown.render(source)
    "#{new_source.inspect}.html_safe;"
  end
end

ActionView::Template.register_template_handler :md, MarkdownHandler
