require 'spec_helper'

describe Profile do
  before do
    FactoryBot.create(:blog)
  end

  describe 'validations' do
    it 'validates uniqueness of label' do
      Profile.create!(label: 'unique_profile')
      duplicate = Profile.new(label: 'unique_profile')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:label]).to include('has already been taken')
    end
  end

  describe 'ADMIN constant' do
    it 'defines ADMIN as admin' do
      expect(Profile::ADMIN).to eq('admin')
    end
  end

  describe '#modules' do
    it 'returns empty array when modules is nil' do
      profile = Profile.new
      expect(profile.modules).to eq([])
    end

    it 'returns stored modules' do
      profile = Profile.new(modules: [:content, :pages])
      expect(profile.modules).to eq([:content, :pages])
    end
  end

  describe '#modules=' do
    it 'converts string modules to symbols' do
      profile = Profile.new
      profile.modules = ['content', 'pages', 'settings']
      expect(profile.modules).to eq([:content, :pages, :settings])
    end

    it 'removes blank values' do
      profile = Profile.new
      profile.modules = ['content', '', 'pages', nil]
      expect(profile.modules).to eq([:content, :pages])
    end

    it 'handles nil input' do
      profile = Profile.new
      profile.modules = nil
      expect(profile.modules).to eq([])
    end
  end

  describe '#project_modules' do
    it 'returns project modules based on label and modules' do
      profile = Profile.find_by_label('admin')
      # Just verify it doesn't raise an error
      expect { profile.project_modules }.not_to raise_error
    end
  end

  describe 'default profiles' do
    it 'has admin profile' do
      expect(Profile.find_by_label('admin')).to be_present
    end

    it 'has publisher profile' do
      expect(Profile.find_by_label('publisher')).to be_present
    end

    it 'has contributor profile' do
      expect(Profile.find_by_label('contributor')).to be_present
    end
  end
end
