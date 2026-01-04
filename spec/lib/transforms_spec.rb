# frozen_string_literal: true

require 'spec_helper'

describe String do
  describe '#to_title' do
    it 'should handle the case where item.body is nil' do
      item = double('item')
      expect(item).to receive(:body).and_return(nil)

      params = {}

      settings = double('settings')
      settings.stub!(:blog_name).and_return('')
      settings.stub!(:blog_subtitle).and_return('')
      settings.stub!(:meta_keywords).and_return('')
      settings.stub!(:date_format).and_return('')
      settings.stub!(:time_format).and_return('')

      '%excerpt%'.to_title(item, settings, params)
    end

    it 'should build a nice permalink from an accentuated string' do
      expect("L'été s'ra chaud, l'été s'ra chaud".to_permalink).to eq('l-ete-s-ra-chaud-l-ete-s-ra-chaud')
    end
  end
end
