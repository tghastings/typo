# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::BaseHelper, type: :helper do
  before do
    create(:blog)
  end

  let(:user) { create(:user) }
  let(:admin_user) { create(:admin_user) }

  describe '#draggable_element' do
    it 'returns empty string' do
      expect(helper.draggable_element('element_id')).to eq('')
    end
  end

  describe '#sortable_element' do
    it 'returns empty string' do
      expect(helper.sortable_element('element_id')).to eq('')
    end
  end

  describe '#menu_url_to_path' do
    it 'returns string URL unchanged' do
      expect(helper.menu_url_to_path('/admin/content')).to eq('/admin/content')
    end

    it 'converts hash to path' do
      url = { controller: 'content', action: 'index' }
      expect(helper.menu_url_to_path(url)).to eq('/admin/content')
    end

    it 'includes action when not index' do
      url = { controller: 'content', action: 'new' }
      expect(helper.menu_url_to_path(url)).to eq('/admin/content/new')
    end

    it 'includes id when provided' do
      url = { controller: 'content', action: 'edit', id: 5 }
      expect(helper.menu_url_to_path(url)).to eq('/admin/content/edit/5')
    end
  end

  describe '#subtab' do
    it 'returns span for empty options' do
      result = helper.subtab('Label', {})
      expect(result).to include('subtabs')
      expect(result).to include('Label')
    end

    it 'returns link for non-empty options' do
      result = helper.subtab('Label', '/admin/content')
      expect(result).to include('Label')
      expect(result).to include('href')
    end
  end

  describe '#show_page_heading' do
    it 'returns nil when page_heading is nil' do
      expect(helper.show_page_heading).to be_nil
    end

    it 'returns div with heading when page_heading is set' do
      assign(:page_heading, 'Test Heading')
      result = helper.show_page_heading
      expect(result).to include('Test Heading')
      expect(result).to include('page-header')
    end
  end

  describe '#save' do
    it 'returns submit button' do
      result = helper.save('Save It')
      expect(result).to include('submit')
      expect(result).to include('Save It')
    end

    it 'uses default value' do
      result = helper.save
      expect(result).to include('submit')
    end
  end

  describe '#text_filter_options' do
    before { create(:textile) }

    it 'returns array of filter options' do
      result = helper.text_filter_options
      expect(result).to be_an(Array)
    end
  end

  describe '#text_filter_options_with_id' do
    before { create(:textile) }

    it 'returns array of filter options with ids' do
      result = helper.text_filter_options_with_id
      expect(result).to be_an(Array)
    end
  end

  describe '#alternate_class' do
    it 'alternates between empty and shade' do
      first = helper.alternate_class
      second = helper.alternate_class
      expect([first, second]).to include('')
      expect([first, second]).to include('class="shade"')
    end
  end

  describe '#class_tab' do
    it 'returns empty string' do
      expect(helper.class_tab).to eq('')
    end
  end

  describe '#class_selected_tab' do
    it 'returns active' do
      expect(helper.class_selected_tab).to eq('active')
    end
  end

  describe '#format_date' do
    it 'formats date correctly' do
      date = Time.zone.local(2024, 6, 15)
      expect(helper.format_date(date)).to eq('15/06/2024')
    end
  end

  describe '#format_date_time' do
    it 'formats date and time correctly' do
      date = Time.zone.local(2024, 6, 15, 14, 30)
      expect(helper.format_date_time(date)).to eq('15/06/2024 14:30')
    end
  end

  describe '#published_or_not' do
    let(:article) { create(:article) }

    it 'returns Published label for published article' do
      article.state = 'published'
      result = helper.published_or_not(article)
      expect(result).to include('Published')
      expect(result).to include('success')
    end

    it 'returns Draft label for draft article' do
      article.state = 'draft'
      result = helper.published_or_not(article)
      expect(result).to include('Draft')
      expect(result).to include('notice')
    end

    it 'returns Withdrawn label for withdrawn article' do
      article.state = 'withdrawn'
      result = helper.published_or_not(article)
      expect(result).to include('Withdrawn')
      expect(result).to include('important')
    end

    it 'returns Publication pending label' do
      item = double('item', state: :publicationpending)
      result = helper.published_or_not(item)
      expect(result).to include('Publication pending')
      expect(result).to include('warning')
    end
  end

  describe '#render_void_table' do
    it 'returns nil when size is not zero' do
      expect(helper.render_void_table(5, 3)).to be_nil
    end

    it 'returns message when size is zero' do
      allow(controller).to receive(:controller_name).and_return('content')
      result = helper.render_void_table(0, 3)
      expect(result).to include('colspan=3')
    end
  end

  describe '#get_short_url' do
    let(:article) { create(:article) }

    it 'returns empty string when short_url is nil' do
      allow(article).to receive(:short_url).and_return(nil)
      expect(helper.get_short_url(article)).to eq('')
    end

    it 'returns link when short_url exists' do
      allow(article).to receive(:short_url).and_return('http://short.url/abc')
      result = helper.get_short_url(article)
      expect(result).to include('Short url')
      expect(result).to include('http://short.url/abc')
    end
  end

  describe '#cancel_or_save' do
    it 'returns cancel and save buttons' do
      allow(controller).to receive(:controller_name).and_return('content')
      result = helper.cancel_or_save
      expect(result).to include('Cancel')
      expect(result).to include('submit')
    end
  end

  describe '#save_settings' do
    it 'returns settings save div' do
      allow(controller).to receive(:controller_name).and_return('settings')
      result = helper.save_settings
      expect(result).to include('Update settings')
      expect(result).to include('actions')
    end
  end

  describe '#macro_help_popup' do
    let(:macro) { double('macro', short_name: 'test_macro', display_name: 'Test Macro') }

    it 'returns popup link' do
      result = helper.macro_help_popup(macro, 'Help')
      expect(result).to include('test_macro')
      expect(result).to include('popup')
    end
  end

  describe '#build_editor_link' do
    it 'returns editor link with spinner' do
      result = helper.build_editor_link('Visual', 'switch', 'editor', 'update', 'visual')
      expect(result).to include('Visual')
      expect(result).to include('switchEditor')
    end
  end

  describe '#collection_select_with_current' do
    let(:items) do
      [
        double('item', id: 1, name: 'First'),
        double('item', id: 2, name: 'Second')
      ]
    end

    it 'returns select element' do
      result = helper.collection_select_with_current('article', 'category_id', items, :id, :name, nil)
      expect(result).to include('select')
      expect(result).to include('First')
      expect(result).to include('Second')
    end

    it 'selects current value' do
      result = helper.collection_select_with_current('article', 'category_id', items, :id, :name, 1)
      expect(result).to include('selected')
    end

    it 'adds prompt when requested' do
      result = helper.collection_select_with_current('article', 'category_id', items, :id, :name, nil, true)
      expect(result).to include('Please select')
    end
  end

  describe '#display_pagination' do
    it 'returns pagination row' do
      collection = double('collection', total_pages: 1, current_page: 1, limit_value: 10, size: 0)
      allow(collection).to receive(:each).and_return([])
      result = helper.display_pagination(collection, 3)
      expect(result).to include('colspan=3')
      expect(result).to include('paginate')
    end
  end
end
