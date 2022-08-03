# frozen_string_literal: true

RSpec.shared_examples 'a resource with a thumbnail selection' do
  describe 'validations' do
    subject { resource }

    it { is_expected.to validate_presence_of(:thumbnail_selection) }

    it do
      expect(subject).to validate_inclusion_of(:thumbnail_selection).in_array([ThumbnailSelections::DEFAULT_ICON,
                                                                               ThumbnailSelections::AUTO_GENERATED,
                                                                               ThumbnailSelections::UPLOADED_IMAGE])
    end
  end

  describe '#auto_generated_thumbnail?' do
    context "when thumbnail_selection is '#{ThumbnailSelections::AUTO_GENERATED}'" do
      before do
        resource.update thumbnail_selection: ThumbnailSelections::AUTO_GENERATED
      end

      it 'returns true' do
        expect(resource.auto_generated_thumbnail?).to be true
      end
    end

    context "when thumbnail_selection is not '#{ThumbnailSelections::AUTO_GENERATED}'" do
      before do
        resource.update thumbnail_selection: ThumbnailSelections::DEFAULT_ICON
      end

      it 'returns false' do
        expect(resource.auto_generated_thumbnail?).to be false
      end
    end
  end

  describe '#default_thumbnail?' do
    context "when thumbnail_selection is '#{ThumbnailSelections::DEFAULT_ICON}'" do
      before do
        resource.update thumbnail_selection: ThumbnailSelections::DEFAULT_ICON
      end

      it 'returns true' do
        expect(resource.default_thumbnail?).to be true
      end
    end

    context "when thumbnail_selection is not '#{ThumbnailSelections::DEFAULT_ICON}'" do
      before do
        resource.update thumbnail_selection: ThumbnailSelections::AUTO_GENERATED
      end

      it 'returns false' do
        expect(resource.default_thumbnail?).to be false
      end
    end
  end
end
