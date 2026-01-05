# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Profile, type: :model do
  describe 'factory' do
    it 'creates valid profile' do
      profile = create(:profile)
      expect(profile).to be_valid
    end

    it 'creates admin profile' do
      profile = create(:profile_admin)
      expect(profile.label).to eq('admin')
    end

    it 'creates publisher profile' do
      profile = create(:profile_publisher)
      expect(profile.label).to eq('publisher')
    end

    it 'creates contributor profile' do
      profile = create(:profile_contributor)
      expect(profile.label).to eq('contributor')
    end
  end

  describe '#modules' do
    it 'returns array of modules' do
      profile = create(:profile_admin)
      expect(profile.modules).to be_an(Array)
      expect(profile.modules).to include(:dashboard)
    end
  end

  describe '#project_modules' do
    it 'returns project modules' do
      profile = create(:profile_admin)
      expect(profile.project_modules).to be_an(Array)
    end
  end

  describe 'ADMIN constant' do
    it 'equals admin string' do
      expect(Profile::ADMIN).to eq('admin')
    end
  end
end
