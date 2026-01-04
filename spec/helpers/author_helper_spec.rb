# frozen_string_literal: true

require 'spec_helper'

describe AuthorsHelper, 'display_profile_item' do
  include AuthorsHelper

  it 'should display the item as a list item if show_item is true' do
    item = display_profile_item('my@jabber.org', true, 'Jabber:')
    expect(item).to have_selector('li', text: 'Jabber: my@jabber.org')
  end

  it 'should NOT display the item as a list item if show_item is false' do
    item = display_profile_item('my@jabber.org', false, 'Jabber:')
    expect(item).to be_nil
  end

  it 'should display a link if the item is an url' do
    item = display_profile_item('http://twitter.com/mytwitter', true, 'Twitter:')
    expect(item).to have_selector('li') do
      have_selector('a', content: 'http://twitter.com/mytwitter')
    end
  end
end
