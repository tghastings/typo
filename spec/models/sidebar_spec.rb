# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebar, type: :model do
  before do
    create(:blog)
  end

  describe '.available_sidebars' do
    it 'returns list of available sidebar types' do
      result = Sidebar.available_sidebars
      expect(result).to be_an(Array)
    end

    it 'returns sidebar subclasses' do
      expect(Sidebar.available_sidebars).to all(be < Sidebar)
    end
  end

  describe '.find_all_visible' do
    it 'returns sidebars with active_position' do
      Sidebar.create!(type: 'SearchSidebar', active_position: 0)
      expect(Sidebar.find_all_visible).not_to be_empty
    end

    it 'does not return sidebars without active_position' do
      sidebar = Sidebar.create!(type: 'SearchSidebar', active_position: nil)
      expect(Sidebar.find_all_visible).not_to include(sidebar)
    end
  end

  describe '.find_all_staged' do
    it 'returns sidebars with staged_position' do
      Sidebar.create!(type: 'SearchSidebar', staged_position: 0)
      expect(Sidebar.find_all_staged).not_to be_empty
    end
  end

  describe '.purge' do
    it 'removes sidebars without active or staged position' do
      Sidebar.create!(type: 'SearchSidebar', active_position: nil, staged_position: nil)
      expect { Sidebar.purge }.to change(Sidebar, :count).by(-1)
    end

    it 'keeps sidebars with active_position' do
      sidebar = Sidebar.create!(type: 'SearchSidebar', active_position: 0)
      Sidebar.purge
      expect(Sidebar.exists?(sidebar.id)).to be true
    end
  end

  describe '.short_name' do
    it 'returns shortened name' do
      expect(SearchSidebar.short_name).to eq('search')
    end
  end

  describe '.path_name' do
    it 'returns underscored path' do
      expect(SearchSidebar.path_name).to eq('search_sidebar')
    end
  end

  describe '.display_name' do
    it 'returns humanized name' do
      expect(SearchSidebar.display_name).to be_a(String)
    end
  end

  describe '#html_id' do
    it 'returns HTML-safe ID' do
      sidebar = Sidebar.new
      sidebar.id = 123
      expect(sidebar.html_id).to include('123')
    end

    it 'includes short_name' do
      sidebar = SearchSidebar.create!(active_position: 0)
      expect(sidebar.html_id).to include('search')
    end
  end

  describe '#description' do
    it 'returns description' do
      sidebar = Sidebar.new
      expect(sidebar.description).to be_nil.or be_a(String)
    end
  end

  describe '#blog' do
    it 'returns the default blog' do
      sidebar = Sidebar.new
      expect(sidebar.blog).to eq(Blog.default)
    end
  end

  describe '#config' do
    it 'returns empty hash by default' do
      sidebar = Sidebar.new
      expect(sidebar.config).to be_a(Hash)
    end

    it 'stores configuration' do
      sidebar = Sidebar.new
      sidebar.config['title'] = 'Test Title'
      expect(sidebar.config['title']).to eq('Test Title')
    end
  end

  describe '#publish' do
    it 'sets active_position to staged_position' do
      sidebar = Sidebar.new(staged_position: 5)
      sidebar.publish
      expect(sidebar.active_position).to eq(5)
    end
  end

  describe '#fields' do
    it 'returns class fields' do
      sidebar = SearchSidebar.new
      expect(sidebar.fields).to be_an(Array)
    end
  end

  describe '#to_locals_hash' do
    it 'returns hash with sidebar' do
      sidebar = SearchSidebar.new
      expect(sidebar.to_locals_hash).to include(sidebar: sidebar)
    end
  end

  describe '#content_partial' do
    it 'returns partial path' do
      sidebar = SearchSidebar.new
      expect(sidebar.content_partial).to eq('/search_sidebar/content')
    end
  end

  describe '#valid_sidebar_type?' do
    it 'returns true for valid sidebar subclass' do
      sidebar = SearchSidebar.new
      expect(sidebar.valid_sidebar_type?).to be true
    end
  end

  describe 'Field' do
    let(:field) { Sidebar::Field.new(:test_key, 'default', {}) }

    describe '#label' do
      it 'returns humanized key' do
        expect(field.label).to eq('Test key')
      end

      it 'uses custom label if provided' do
        custom = Sidebar::Field.new(:test_key, 'default', label: 'Custom Label')
        expect(custom.label).to eq('Custom Label')
      end
    end

    describe '#canonicalize' do
      it 'returns value unchanged' do
        expect(field.canonicalize('test')).to eq('test')
      end
    end

    describe '.build' do
      it 'creates text field by default' do
        field = Sidebar::Field.build(:test, 'default', {})
        expect(field).to be_a(Sidebar::Field)
      end

      it 'creates select field when choices provided' do
        field = Sidebar::Field.build(:test, 'default', choices: [['a', 'A']])
        expect(field).to be_a(Sidebar::Field::SelectField)
      end

      it 'creates text area field' do
        field = Sidebar::Field.build(:test, 'default', input_type: :text_area)
        expect(field).to be_a(Sidebar::Field::TextAreaField)
      end

      it 'creates checkbox field' do
        field = Sidebar::Field.build(:test, 'default', input_type: :checkbox)
        expect(field).to be_a(Sidebar::Field::CheckBoxField)
      end

      it 'creates radio field' do
        field = Sidebar::Field.build(:test, 'default', input_type: :radio)
        expect(field).to be_a(Sidebar::Field::RadioField)
      end
    end
  end

  describe 'CheckBoxField' do
    let(:field) { Sidebar::Field::CheckBoxField.new(:enabled, false, {}) }

    describe '#canonicalize' do
      it 'converts "0" to false' do
        expect(field.canonicalize('0')).to be false
      end

      it 'converts "1" to true' do
        expect(field.canonicalize('1')).to be true
      end
    end
  end

  describe 'RadioField' do
    let(:field) { Sidebar::Field::RadioField.new(:choice, 'a', choices: [['a', 'Option A'], 'b']) }

    describe '#label_for' do
      it 'returns label from array' do
        expect(field.label_for(['a', 'Option A'])).to eq('Option A')
      end

      it 'humanizes simple value' do
        expect(field.label_for('test_value')).to eq('Test value')
      end
    end

    describe '#value_for' do
      it 'returns value from array' do
        expect(field.value_for(['a', 'Option A'])).to eq('a')
      end

      it 'returns simple value unchanged' do
        expect(field.value_for('b')).to eq('b')
      end
    end
  end
end
