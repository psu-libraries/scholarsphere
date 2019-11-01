# frozen_string_literal: true

require 'scholarsphere/cleaner'

RSpec.describe Scholarsphere::Cleaner do
  describe '#clean_minio' do
    context 'when aws is not installed' do
      before { allow(described_class).to receive(:aws?).and_return(false) }

      it 'writes a warnig message to the console' do
        expect { described_class.clean_minio }.to output(/WARNING: Install aws in order to delete files from minio/).to_stdout
      end
    end
  end
end
