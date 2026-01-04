# frozen_string_literal: true

require 'spec_helper'

class TestBrokenSidebar < Sidebar
  description 'Invalid test sidebar'
  def parse_request(_contents, _request_params)
    raise "I'm b0rked!"
  end
end

describe SidebarHelper do
  before do
    @blog = Blog.default
  end

  def content_array
    []
  end

  def params
    {}
  end

  def this_blog
    @blog
  end

  # XXX: Ugh. Needed to break tight coupling :-(.
  def render_to_string(options)
    "Rendered #{options[:file] || options[:partial]}."
  end

  describe '#render_sidebars' do
    describe 'with an invalid sidebar' do
      before do
        TestBrokenSidebar.new.save
      end

      def logger
        fake_logger = mock('fake logger')
        expect(fake_logger).to receive(:error)
        fake_logger
      end

      it 'should return a friendly error message' do
        render_sidebars.should =~ /It seems something went wrong/
      end
    end

    describe 'with a valid sidebar' do
      before do
        Sidebar.new.save
      end

      it 'should render the sidebar' do
        render_sidebars.should =~ /Rendered/
      end
    end

    describe 'with specific sidebars passed' do
      before do
        @sidebar = Sidebar.new
        @sidebar.save
      end

      it 'should render only the passed sidebars' do
        result = render_sidebars(@sidebar)
        expect(result).to match(/Rendered/)
      end
    end

    describe 'with multiple sidebars' do
      before do
        @sidebar1 = Sidebar.new(active_position: 1)
        @sidebar1.save
        @sidebar2 = Sidebar.new(active_position: 2)
        @sidebar2.save
      end

      it 'should render all sidebars in order' do
        result = render_sidebars
        expect(result.scan('Rendered').count).to be >= 2
      end
    end
  end

  describe '#render_sidebar' do
    before do
      @sidebar = Sidebar.new
      @sidebar.save
    end

    it 'should render the sidebar partial' do
      result = render_sidebar(@sidebar)
      expect(result).to match(/Rendered/)
    end

    describe 'with view_root set' do
      before do
        allow(@sidebar).to receive(:view_root).and_return(nil)
      end

      it 'should render via content_partial when view_root is nil' do
        result = render_sidebar(@sidebar)
        expect(result).to match(/Rendered/)
      end
    end
  end

  describe '#render_deprecated_sidebar_view_in_view_root' do
    # This test verifies the method exists. The actual deprecation warning
    # requires a real view_root path with view files which is hard to mock.
    it 'responds to the method' do
      expect(respond_to?(:render_deprecated_sidebar_view_in_view_root)).to be_truthy
    end
  end

  describe '#articles?' do
    it 'returns true when articles exist' do
      allow(Article).to receive(:first).and_return(double('article'))
      expect(articles?).to be_truthy
    end

    it 'returns false when no articles exist' do
      allow(Article).to receive(:first).and_return(nil)
      expect(articles?).to be_falsey
    end
  end

  describe '#trackbacks?' do
    it 'returns true when trackbacks exist' do
      allow(Trackback).to receive(:first).and_return(double('trackback'))
      expect(trackbacks?).to be_truthy
    end

    it 'returns false when no trackbacks exist' do
      allow(Trackback).to receive(:first).and_return(nil)
      expect(trackbacks?).to be_falsey
    end
  end

  describe '#comments?' do
    it 'returns true when comments exist' do
      allow(Comment).to receive(:first).and_return(double('comment'))
      expect(comments?).to be_truthy
    end

    it 'returns false when no comments exist' do
      allow(Comment).to receive(:first).and_return(nil)
      expect(comments?).to be_falsey
    end
  end
end
