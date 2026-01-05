# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Theme, type: :model do
  describe '#initialize' do
    it 'sets name and path' do
      theme = Theme.new('test-theme', '/path/to/theme')
      expect(theme.name).to eq('test-theme')
      expect(theme.path).to eq('/path/to/theme')
    end
  end

  describe '#layout' do
    it 'returns layouts/default for default action' do
      theme = Theme.new('plain', Theme.theme_path('plain'))
      result = theme.layout(:default)
      expect(result).to include('default')
    end

    it 'handles view_page action' do
      theme = Theme.new('plain', Theme.theme_path('plain'))
      result = theme.layout(:view_page)
      expect(result).to be_a(String)
    end
  end

  describe '#description' do
    it 'returns theme description from about.markdown' do
      theme = Theme.find('plain')
      description = theme.description
      expect(description).to be_a(String)
    end

    it 'returns fallback when about.markdown not found' do
      theme = Theme.new('nonexistent', '/nonexistent/path')
      description = theme.description
      expect(description).to eq('### nonexistent')
    end
  end

  describe '.find' do
    it 'returns a theme by name' do
      theme = Theme.find('plain')
      expect(theme).to be_a(Theme)
      expect(theme.name).to eq('plain')
    end
  end

  describe '.themes_root' do
    it 'returns the themes directory path' do
      expect(Theme.themes_root).to include('themes')
    end
  end

  describe '.theme_path' do
    it 'returns path for theme name' do
      path = Theme.theme_path('plain')
      expect(path).to include('plain')
    end
  end

  describe '.theme_from_path' do
    it 'creates theme from path' do
      theme = Theme.theme_from_path('/themes/test-theme')
      expect(theme).to be_a(Theme)
      expect(theme.name).to eq('test-theme')
    end
  end

  describe '.find_all' do
    it 'returns array of themes' do
      themes = Theme.find_all
      expect(themes).to be_an(Array)
      themes.each { |t| expect(t).to be_a(Theme) }
    end
  end

  describe '.installed_themes' do
    it 'returns array of theme paths' do
      themes = Theme.installed_themes
      expect(themes).to be_an(Array)
    end
  end

  describe '.search_theme_directory' do
    it 'finds themes with about.markdown' do
      themes = Theme.search_theme_directory
      expect(themes).to be_an(Array)
    end
  end
end
