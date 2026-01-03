require 'spec_helper'

describe Typo::Textfilter::Pdf do
  let(:blog) { Factory(:blog) }
  let(:whiteboard) { {} }
  let(:content) { double('content', whiteboard: whiteboard) }

  describe 'plugin registration' do
    it 'is included in available_filters' do
      TextFilter.available_filters.should include(Typo::Textfilter::Pdf)
    end

    it 'is included in macro_filters' do
      TextFilter.macro_filters.should include(Typo::Textfilter::Pdf)
    end

    it 'is registered as a macropost filter' do
      TextFilter.available_filter_types['macropost'].should include(Typo::Textfilter::Pdf)
    end

    it 'has correct display name' do
      Typo::Textfilter::Pdf.display_name.should == 'PDF Slideshow'
    end

    it 'has help text' do
      Typo::Textfilter::Pdf.help_text.should be_present
      Typo::Textfilter::Pdf.help_text.should include('<typo:pdf')
    end
  end

  describe '.macrofilter' do
    def macrofilter(attrib)
      Typo::Textfilter::Pdf.macrofilter(blog, content, attrib, {})
    end

    context 'with valid src attribute' do
      let(:result) { macrofilter('src' => 'presentation.pdf') }

      it 'returns HTML with stimulus controller' do
        result.should include('data-controller="pdf-slideshow"')
      end

      it 'includes the PDF source as data attribute' do
        result.should include('data-pdf-slideshow-src-value')
        result.should include('/files/presentation.pdf')
      end

      it 'includes navigation controls' do
        result.should include('pdf-slideshow-prev')
        result.should include('pdf-slideshow-next')
      end

      it 'includes the slide counter' do
        result.should include('data-pdf-slideshow-target="counter"')
      end

      it 'includes the canvas target' do
        result.should include('data-pdf-slideshow-target="canvas"')
      end

      it 'includes fullscreen button' do
        result.should include('pdf-slideshow-fullscreen')
      end

      it 'sets whiteboard page_header for CSS' do
        macrofilter('src' => 'test.pdf')
        whiteboard['page_header_pdf_slideshow'].should include('pdf_slideshow.css')
      end

      it 'sets whiteboard page_header for PDF.js' do
        macrofilter('src' => 'test.pdf')
        whiteboard['page_header_pdf_slideshow'].should include('pdf.min.js')
      end
    end

    context 'with title attribute' do
      let(:result) { macrofilter('src' => 'test.pdf', 'title' => 'My Presentation') }

      it 'includes the title in output' do
        result.should include('My Presentation')
        result.should include('pdf-slideshow-title')
      end
    end

    context 'with width and height attributes' do
      let(:result) { macrofilter('src' => 'test.pdf', 'width' => '800', 'height' => '600') }

      it 'applies custom width' do
        result.should include('width: 800px')
      end

      it 'applies custom height' do
        result.should include('height: 600px')
      end
    end

    context 'with autoplay attributes' do
      let(:result) { macrofilter('src' => 'test.pdf', 'autoplay' => 'true', 'interval' => '3000') }

      it 'includes autoplay data attribute' do
        result.should include('data-pdf-slideshow-autoplay-value="true"')
      end

      it 'includes interval data attribute' do
        result.should include('data-pdf-slideshow-interval-value="3000"')
      end
    end

    context 'with start page attribute' do
      let(:result) { macrofilter('src' => 'test.pdf', 'start' => '5') }

      it 'includes start page data attribute' do
        result.should include('data-pdf-slideshow-start-page-value="5"')
      end
    end

    context 'without src attribute' do
      let(:result) { macrofilter({}) }

      it 'returns error message' do
        result.should include('pdf-slideshow-error')
        result.should include('No PDF source specified')
      end
    end

    context 'with external URL' do
      let(:result) { macrofilter('src' => 'https://example.com/doc.pdf') }

      it 'uses the full URL directly' do
        result.should include('data-pdf-slideshow-src-value="https://example.com/doc.pdf"')
      end
    end

    context 'with http URL' do
      let(:result) { macrofilter('src' => 'http://example.com/doc.pdf') }

      it 'uses the http URL directly' do
        result.should include('data-pdf-slideshow-src-value="http://example.com/doc.pdf"')
      end
    end

    context 'with nil content' do
      it 'does not raise an error' do
        expect {
          Typo::Textfilter::Pdf.macrofilter(blog, nil, { 'src' => 'test.pdf' }, {})
        }.not_to raise_error
      end

      it 'still returns valid HTML' do
        result = Typo::Textfilter::Pdf.macrofilter(blog, nil, { 'src' => 'test.pdf' }, {})
        result.should include('data-controller="pdf-slideshow"')
      end
    end

    context 'XSS prevention' do
      it 'escapes title attribute' do
        result = macrofilter('src' => 'test.pdf', 'title' => '<script>alert("xss")</script>')
        result.should_not include('<script>alert')
      end

      it 'escapes src attribute in output' do
        result = macrofilter('src' => '"><script>alert("xss")</script><"')
        result.should_not include('<script>alert')
      end
    end
  end

  describe 'text filter integration' do
    def filter_text(text, filters = [:macropre, :macropost])
      TextFilter.filter_text(blog, text, content, filters, {})
    end

    it 'processes pdf macro in article text' do
      result = filter_text('<typo:pdf src="slides.pdf"/>')
      result.should include('data-controller="pdf-slideshow"')
    end

    it 'processes self-closing pdf tag' do
      result = filter_text('<typo:pdf src="slides.pdf" />')
      result.should include('data-controller="pdf-slideshow"')
    end

    it 'processes multiple pdf macros' do
      result = filter_text('<typo:pdf src="a.pdf"/><typo:pdf src="b.pdf"/>')
      result.scan('data-controller="pdf-slideshow"').count.should == 2
    end

    it 'works with markdown filter chain' do
      result = filter_text("# Title\n\n<typo:pdf src=\"slides.pdf\"/>\n\nSome text",
                           [:macropre, :markdown, :macropost])
      result.should include('<h1')
      result.should include('data-controller="pdf-slideshow"')
    end

    it 'processes pdf tag with multiple attributes' do
      result = filter_text('<typo:pdf src="deck.pdf" title="My Deck" width="800"/>')
      result.should include('My Deck')
      result.should include('width: 800px')
    end
  end
end
