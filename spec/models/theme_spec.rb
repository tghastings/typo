# frozen_string_literal: true

require 'spec_helper'

describe 'Given a new test theme' do
  it %(layout path should be "#{Rails.root}/themes/test/layouts/default") do
    theme = Theme.new('test', 'test')
    theme.layout('index').should == "#{Rails.root}/themes/test/layouts/default"
  end
end

describe 'Given the default theme' do
  before(:each) do
    Factory(:blog)
    @theme = Blog.default.current_theme
  end

  it 'theme should be scribbish' do
    @theme.name.should == 'scribbish'
  end

  it 'theme description should be correct' do
    @theme.description.should ==
      File.read("#{Rails.root}/themes/scribbish/about.markdown")
  end

  it 'theme_from_path should find the correct theme' do
    Theme.theme_from_path("#{Rails.root}themes/scribbish").name.should == 'scribbish'
  end

  it '#search_theme_path finds the right things 2' do
    fake_blue_theme_dir = 'fake_blue_theme_dir'
    fake_red_theme_dir = 'fake_red_theme_dir'
    fake_bad_theme_dir = 'fake_bad_theme_dir'
    expect(Dir).to receive(:glob).and_return([fake_blue_theme_dir, fake_bad_theme_dir, fake_red_theme_dir])
    expect(File).to receive(:readable?).with("#{fake_blue_theme_dir}/about.markdown").and_return(true)
    expect(File).to receive(:readable?).with("#{fake_bad_theme_dir}/about.markdown").and_return(false)
    expect(File).to receive(:readable?).with("#{fake_red_theme_dir}/about.markdown").and_return(true)
    Theme.search_theme_directory.should == %w[fake_blue_theme_dir fake_red_theme_dir]
  end

  it 'find_all finds all the installed themes' do
    Theme.find_all.size.should ==
      Dir.glob("#{Rails.root}/themes/[a-zA-Z0-9]*").select do |file|
        File.readable? "#{file}/about.markdown"
      end.size
  end
end
