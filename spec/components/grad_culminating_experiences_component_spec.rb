# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GradCulminatingExperiencesDropdownsComponent, type: :component do
  let(:resource) { instance_double('Resource',
                                   work: work) }
  let(:work) { instance_double('Work',
                               masters_culminating_experience?: false,
                               professional_doctoral_culminating_experience?: false) }
  let(:form) { instance_double('Form') }
  let(:component) { described_class.new(form: form, resource: resource) }

  describe '#sub_work_type_dropdown' do
    context 'when work type is professional doctoral culminating experience' do
      before do
        allow(work).to receive(:professional_doctoral_culminating_experience?).and_return(true)
      end

      it 'returns the correct dropdown options' do
        expect(component.sub_work_type_dropdown).to eq([
                                                         'Capstone Project',
                                                         'Culminating Research Project',
                                                         'Doctor of Nursing Practice Project',
                                                         'Integrative Doctoral Research Project',
                                                         'Praxis Project',
                                                         'Public Performance'
                                                       ])
      end
    end

    context 'when work type is masters culminating experience' do
      before do
        allow(work).to receive(:masters_culminating_experience?).and_return(true)
      end

      it 'returns the correct dropdown options' do
        expect(component.sub_work_type_dropdown).to eq([
                                                         'Capstone Course Work Product',
                                                         'Capstone Project',
                                                         'Scholarly Paper/Essay (MA/MS)'
                                                       ])
      end
    end

    context 'when work type is not recognized' do
      before do
        allow(resource).to receive(:work_type).and_return(nil)
      end

      it 'returns nil' do
        expect(component.sub_work_type_dropdown).to be_nil
      end
    end
  end

  describe '#programs_dropdown' do
    it 'returns programs from the file based authority graduate_programs' do
      expect(component.programs_dropdown).to eq(Qa::Authorities::Local::FileBasedAuthority.new(:graduate_programs)
        .all
        .filter_map { |p| p['label'] })
    end
  end

  describe '#degrees_dropdown' do
    context 'when work type is professional doctoral culminating experience' do
      before do
        allow(work).to receive(:professional_doctoral_culminating_experience?).and_return(true)
      end

      it 'returns degrees from the file based authority doctoral_degrees' do
        expect(component.degrees_dropdown).to eq(Qa::Authorities::Local::FileBasedAuthority.new(:doctoral_degrees)
          .all
          .filter_map { |p| p['label'] })
      end
    end

    context 'when work type is masters culminating experience' do
      before do
        allow(work).to receive(:masters_culminating_experience?).and_return(true)
      end

      it 'returns degrees from the file based authority masters_degrees' do
        expect(component.degrees_dropdown).to eq(Qa::Authorities::Local::FileBasedAuthority.new(:masters_degrees)
          .all
          .filter_map { |p| p['label'] })
      end
    end

    context 'when work type is not recognized' do
      before do
        allow(resource).to receive(:work_type).and_return(nil)
      end

      it 'returns nil' do
        expect(component.degrees_dropdown).to be_nil
      end
    end
  end
end
