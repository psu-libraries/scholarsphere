# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileSignatureComponent, type: :component do
  let(:content) { render_inline(described_class.new(file: file)).to_s }
  let(:membership) { build :file_version_membership }
  let(:file_resource) { membership.file_resource }
  let(:file) { file_resource.file }

  context 'when the file has a sha256 signature' do
    it 'displays a sha256 signature' do
      expect(content).to include 'sha256:'
    end
  end

  context 'when the file has only md5 signature' do
    it 'displays a md5 signature' do
      file.metadata.delete 'sha256'

      expect(content).not_to include 'sha256:'
      expect(content).to include 'md5:'
    end
  end

  context 'when the file does not have a signature' do
    it 'does not display a signature' do
      file.metadata.delete 'sha256'
      file.metadata.delete 'md5'

      expect(content).not_to include 'sha256:'
      expect(content).not_to include 'md5:'
    end
  end
end
