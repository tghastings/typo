require 'spec_helper'

describe TextFilter do
  describe 'Factory' do
    it 'should create a valid text_filter' do
      text_filter = Factory(:text_filter)
      text_filter.should be_valid
    end

    it 'should build a valid text_filter' do
      text_filter = Factory.build(:text_filter)
      text_filter.should be_valid
    end

    it 'creates markdown filter' do
      filter = Factory(:markdown)
      filter.name.should == 'markdown'
      filter.markup.should == 'markdown'
    end

    it 'creates textile filter' do
      filter = Factory(:textile)
      filter.name.should == 'textile'
      filter.markup.should == 'textile'
    end

    it 'creates smartypants filter' do
      filter = Factory(:smartypants)
      filter.name.should == 'smartypants'
      filter.markup.should == 'none'
    end

    it 'creates markdown_smartypants filter' do
      filter = Factory(:markdown_smartypants)
      filter.name.should == 'markdown smartypants'
      filter.markup.should == 'markdown'
    end

    it 'creates none filter' do
      filter = Factory(:none_filter)
      filter.name.should == 'none'
      filter.markup.should == 'none'
    end
  end

  describe 'serialization' do
    it 'serializes filters attribute' do
      filter = TextFilter.new(name: 'test', filters: [:smartypants, :markdown])
      filter.save
      filter.reload
      filter.filters.should be_a(Array)
    end

    it 'serializes params attribute' do
      filter = TextFilter.new(name: 'test', params: { key: 'value' })
      filter.save
      filter.reload
      filter.params.should be_a(Hash)
    end
  end

  describe '#to_s' do
    it 'returns the name of the filter' do
      filter = TextFilter.new(name: 'my_filter')
      filter.to_s.should == 'my_filter'
    end
  end

  describe '#to_text_filter' do
    it 'returns self' do
      filter = TextFilter.new(name: 'test')
      filter.to_text_filter.should == filter
    end
  end

  describe '#sanitize' do
    it 'delegates to class method' do
      filter = TextFilter.new
      expect(TextFilter).to receive(:sanitize).with('test', :option).and_return('sanitized')
      filter.sanitize('test', :option).should == 'sanitized'
    end
  end

  describe 'With the list of available filters' do
    attr_reader :blog, :whiteboard

    before(:each) do
      @blog = Factory(:blog)
      @filters = TextFilter.available_filters
      @whiteboard = Hash.new
    end

    describe '#available_filters' do
      subject { @filters }
      it { should include(Typo::Textfilter::Markdown) }
      it { should include(Typo::Textfilter::Smartypants) }
      it { should include(Typo::Textfilter::Htmlfilter) }
      it { should include(Typo::Textfilter::Textile) }
      it { should include(Typo::Textfilter::Flickr) }
      it { should include(Typo::Textfilter::Code) }
      it { should include(Typo::Textfilter::Lightbox) }
      it { should_not include(TextFilterPlugin::Markup) }
      it { should_not include(TextFilterPlugin::Macro) }
    end

    describe '#macro_filters' do
      subject { TextFilter.macro_filters }
      it { should_not include(Typo::Textfilter::Markdown) }
      it { should_not include(Typo::Textfilter::Smartypants) }
      it { should_not include(Typo::Textfilter::Htmlfilter) }
      it { should_not include(Typo::Textfilter::Textile) }
      it { should include(Typo::Textfilter::Flickr) }
      it { should include(Typo::Textfilter::Code) }
      it { should include(Typo::Textfilter::Lightbox) }
      it { should_not include(TextFilterPlugin::Markup) }
      it { should_not include(TextFilterPlugin::Macro) }
    end

    describe '.filters_map' do
      it 'returns the TextFilterPlugin filter_map' do
        TextFilter.filters_map.should == TextFilterPlugin.filter_map
      end

      it 'returns a hash with filter names as keys' do
        TextFilter.filters_map.should be_a(Hash)
      end
    end

    describe '.available_filter_types' do
      subject { TextFilter.available_filter_types }

      it 'returns a hash with filter type keys' do
        subject.should be_a(Hash)
        subject.keys.should include('markup', 'macropre', 'macropost', 'postprocess', 'other')
      end

      it 'groups markup filters correctly' do
        subject['markup'].should include(Typo::Textfilter::Markdown)
        subject['markup'].should include(Typo::Textfilter::Textile)
      end

      it 'groups macro filters correctly' do
        subject['macropre'].should include(Typo::Textfilter::Code)
        subject['macropost'].should include(Typo::Textfilter::Flickr)
        subject['macropost'].should include(Typo::Textfilter::Lightbox)
      end

      it 'caches the filter types' do
        first_call = TextFilter.available_filter_types
        second_call = TextFilter.available_filter_types
        first_call.object_id.should == second_call.object_id
      end
    end

    describe '#filter_text' do
      def filter_text(text, filters, filterparams = {})
        TextFilter.filter_text(blog, text, self, filters, filterparams)
      end

      it 'returns unmodified text for unknown filter' do
        text = filter_text('*foo*', [:unknowndoesnotexist])
        text.should == '*foo*'
      end

      it 'returns unmodified text when filter is nil' do
        text = filter_text('*foo*', [nil])
        text.should == '*foo*'
      end

      it 'applies smartypants filter' do
        Factory(:smartypants)
        text = filter_text('"foo"', [:smartypants])
        text.should == '&#8220;foo&#8221;'
      end

      it 'applies markdown filter' do
        Factory(:markdown)
        text = filter_text('*foo*', [:markdown])
        assert_equal '<p><em>foo</em></p>', text.strip

        text = filter_text("foo\n\nbar", [:markdown])
        assert_equal "<p>foo</p>\n\n<p>bar</p>", text.strip
      end

      it 'chains multiple filters' do
        Factory(:markdown)
        Factory(:smartypants)
        result = filter_text('*"foo"*', [:markdown, :smartypants]).strip
        # Should have markdown emphasis applied
        expect(result).to include('<em>')
        expect(result).to include('foo')
        expect(result).to include('</em>')

        result2 = filter_text('*"foo"*', [:doesntexist1, :markdown, "doesn't exist 2", :smartypants, :nopenotmeeither]).strip
        expect(result2).to include('<em>')
        expect(result2).to include('foo')
      end

      it 'logs errors for failed filters' do
        allow(TextFilter).to receive(:filters_map).and_return({ 'bad_filter' => double(filtertext: nil) })
        allow_any_instance_of(Object).to receive(:filtertext).and_raise(StandardError.new('test error'))
        # Should not raise, just log
        expect { filter_text('test', [:bad_filter]) }.not_to raise_error
      end

      describe 'specific typo tags' do
        describe 'flickr' do
          it 'should show with default settings' do
            assert_equal "<div style=\"float:left\" class=\"flickrplugin\"><a href=\"http://www.flickr.com/users/scottlaird/31366117\"><img src=\"http://photos23.flickr.com/31366117_b1a791d68e_s.jpg\" width=\"75\" height=\"75\" alt=\"Matz\" title=\"Matz\"/></a><p class=\"caption\" style=\"width:75px\">This is Matz, Ruby's creator</p></div>",
                         filter_text('<typo:flickr img="31366117" size="Square" style="float:left"/>',
                                     [:macropre, :macropost],
                                     { 'flickr-user' => 'scott@sigkill.org' })
          end

          it 'should use default image size' do
            assert_equal "<div style=\"\" class=\"flickrplugin\"><a href=\"http://www.flickr.com/users/scottlaird/31366117\"><img src=\"http://photos23.flickr.com/31366117_b1a791d68e_s.jpg\" width=\"75\" height=\"75\" alt=\"Matz\" title=\"Matz\"/></a><p class=\"caption\" style=\"width:75px\">This is Matz, Ruby's creator</p></div>",
                         filter_text('<typo:flickr img="31366117"/>',
                                     [:macropre, :macropost],
                                     { 'flickr-user' => 'scott@sigkill.org' })
          end

          it 'should use caption' do
            assert_equal "<div style=\"\" class=\"flickrplugin\"><a href=\"http://www.flickr.com/users/scottlaird/31366117\"><img src=\"http://photos23.flickr.com/31366117_b1a791d68e_s.jpg\" width=\"75\" height=\"75\" alt=\"Matz\" title=\"Matz\"/></a></div>",
                         filter_text('<typo:flickr img="31366117" caption=""/>',
                                     [:macropre, :macropost],
                                     { 'flickr-user' => 'scott@sigkill.org' })
          end

          it 'broken_flickr_link' do
            assert_equal %{<div class='broken_flickr_link'>\`notaflickrid\' could not be displayed because: <br />Photo not found</div>},
                         filter_text('<typo:flickr img="notaflickrid" />',
                                     [:macropre, :macropost],
                                     { 'flickr-user' => 'scott@sigkill.org' })
          end
        end
      end

      describe 'code textfilter' do
        describe 'single line' do
          it 'should made nothin if no args' do
            filter_text('<typo:code>foo-code</typo:code>', [:macropre, :macropost]).should == %{<div class="CodeRay"><pre><notextile>foo-code</notextile></pre></div>}
          end

          it 'should parse ruby lang' do
            filter_text('<typo:code lang="ruby">foo-code</typo:code>', [:macropre, :macropost]).should == %{<div class="CodeRay"><pre><notextile><span class=\"CodeRay\">foo-code</span></notextile></pre></div>}
          end

          it 'should parse ruby and xml in same sentence but not in same place' do
            filter_text('<typo:code lang="ruby">foo-code</typo:code> blah blah <typo:code lang="xml">zzz</typo:code>', [:macropre, :macropost]).should == %{<div class="CodeRay"><pre><notextile><span class="CodeRay">foo-code</span></notextile></pre></div> blah blah <div class="CodeRay"><pre><notextile><span class="CodeRay">zzz</span></notextile></pre></div>}
          end
        end

        describe 'multiline' do
          it 'should render ruby' do
            filter_text(%{
<typo:code lang="ruby">
class Foo
  def bar
    @a = "zzz"
  end
end
</typo:code>
          }, [:macropre, :macropost]).should == %{
<div class=\"CodeRay\"><pre><notextile><span class=\"CodeRay\"><span class=\"keyword\">class</span> <span class=\"class\">Foo</span>
  <span class=\"keyword\">def</span> <span class=\"function\">bar</span>
    <span class=\"instance-variable\">@a</span> = <span class=\"string\"><span class=\"delimiter\">&quot;</span><span class=\"content\">zzz</span><span class=\"delimiter\">&quot;</span></span>
  <span class=\"keyword\">end</span>
<span class=\"keyword\">end</span></span></notextile></pre></div>
          }
          end
        end
      end

      it 'test_code_plus_markup_chain' do
        text = <<-EOF
*header text here*

<typo:code lang="ruby">
class test
  def method
    "foo"
  end
end
</typo:code>

_footer text here_

        EOF

        expects_markdown = <<-EOF
<p><em>header text here</em></p>

<div class="CodeRay"><pre><span class="CodeRay"><span class="keyword">class</span> <span class="class">test</span>
  <span class="keyword">def</span> <span class="function">method</span>
    <span class="string"><span class="delimiter">&quot;</span><span class="content">foo</span><span class="delimiter">&quot;</span></span>
  <span class="keyword">end</span>
<span class="keyword">end</span></span></pre></div>

<p><em>footer text here</em></p>
        EOF

        expects_textile = <<-EOF
<p><strong>header text here</strong></p>
<div class="CodeRay"><pre><span class="CodeRay"><span class="keyword">class</span> <span class="class">test</span>
  <span class="keyword">def</span> <span class="function">method</span>
    <span class="string"><span class="delimiter">&quot;</span><span class="content">foo</span><span class="delimiter">&quot;</span></span>
  <span class="keyword">end</span>
<span class="keyword">end</span></span></pre></div>
<p><em>footer text here</em></p>
        EOF

        assert_equal expects_markdown.strip, TextFilter.filter_text_by_name(blog, text, 'markdown').strip
        assert_equal expects_textile.strip, TextFilter.filter_text_by_name(blog, text, 'textile').strip
      end

      context 'lightbox' do
        it 'should work' do
          assert_equal "<a href=\"http://photos23.flickr.com/31366117_b1a791d68e_b.jpg\" rel=\"lightbox\" title=\"Matz\"><img src=\"http://photos23.flickr.com/31366117_b1a791d68e_t.jpg\" width=\"67\" height=\"100\" alt=\"Matz\" title=\"Matz\"/></a><p class=\"caption\" style=\"width:67px\">This is Matz, Ruby's creator</p>",
                       filter_text('<typo:lightbox img="31366117" thumbsize="Thumbnail" displaysize="Large" style="float:left"/>',
                                   [:macropre, :macropost],
                                   {})
        end

        it 'shoudl use default thumb image size' do
          assert_equal "<a href=\"http://photos23.flickr.com/31366117_b1a791d68e_b.jpg\" rel=\"lightbox\" title=\"Matz\"><img src=\"http://photos23.flickr.com/31366117_b1a791d68e_s.jpg\" width=\"75\" height=\"75\" alt=\"Matz\" title=\"Matz\"/></a><p class=\"caption\" style=\"width:75px\">This is Matz, Ruby's creator</p>",
                       filter_text('<typo:lightbox img="31366117" displaysize="Large"/>',
                                   [:macropre, :macropost],
                                   {})
        end

        it 'should use default display image size' do
          assert_equal "<a href=\"http://photos23.flickr.com/31366117_b1a791d68e_o.jpg\" rel=\"lightbox\" title=\"Matz\"><img src=\"http://photos23.flickr.com/31366117_b1a791d68e_s.jpg\" width=\"75\" height=\"75\" alt=\"Matz\" title=\"Matz\"/></a><p class=\"caption\" style=\"width:75px\">This is Matz, Ruby's creator</p>",
                       filter_text('<typo:lightbox img="31366117"/>',
                                   [:macropre, :macropost],
                                   {})
        end

        it 'should work with caption' do
          assert_equal "<a href=\"http://photos23.flickr.com/31366117_b1a791d68e_o.jpg\" rel=\"lightbox\" title=\"Matz\"><img src=\"http://photos23.flickr.com/31366117_b1a791d68e_s.jpg\" width=\"75\" height=\"75\" alt=\"Matz\" title=\"Matz\"/></a>",
                       filter_text('<typo:lightbox img="31366117" caption=""/>',
                                   [:macropre, :macropost],
                                   {})
        end
      end

      describe 'combining a post-macro' do
        describe 'with markdown' do
          it 'correctly interprets the macro' do
            result = filter_text('<typo:flickr img="31366117" size="Square" style="float:left"/>',
                                 [:macropre, :markdown, :macropost])
            result.should =~ %r{<div style="float:left" class="flickrplugin"><a href="http://www.flickr.com/users/scottlaird/31366117"><img src="http://photos23.flickr.com/31366117_b1a791d68e_s.jpg" width="75" height="75" alt="Matz" title="Matz"/></a><p class="caption" style="width:75px">This is Matz, Ruby's creator</p></div>}
          end
        end

        describe 'with textile' do
          it 'correctly interprets the macro' do
            result = filter_text('<typo:flickr img="31366117" size="Square" style="float:left"/>',
                                 [:macropre, :textile, :macropost])
            result.should == "<div style=\"float:left\" class=\"flickrplugin\"><a href=\"http://www.flickr.com/users/scottlaird/31366117\"><img src=\"http://photos23.flickr.com/31366117_b1a791d68e_s.jpg\" width=\"75\" height=\"75\" alt=\"Matz\" title=\"Matz\"/></a><p class=\"caption\" style=\"width:75px\">This is Matz, Ruby's creator</p></div>"
          end
        end
      end
    end

    describe '.filter_text_by_name' do
      it 'filters text using the named filter' do
        Factory(:markdown_smartypants)
        result = TextFilter.filter_text_by_name(blog, '*"foo"*', 'markdown smartypants')
        # Should have markdown emphasis and either smart quotes or regular quotes
        result.strip.should include('<em>')
        result.strip.should include('</em>')
        result.strip.should match(/foo/)
      end

      it 'finds filter by name and applies it' do
        Factory(:markdown)
        result = TextFilter.filter_text_by_name(blog, '**bold**', 'markdown')
        result.should include('<strong>bold</strong>')
      end
    end
  end

  describe '#filter_text_for_content' do
    let(:blog) { Factory(:blog) }

    it 'applies the filter chain with macros' do
      filter = TextFilter.new(name: 'test', markup: 'none', filters: [], params: {})
      allow(TextFilter).to receive(:filter_text).and_return('filtered text')

      expect(TextFilter).to receive(:filter_text).with(
        blog,
        'input text',
        nil,
        [:macropre, 'none', :macropost, []].flatten,
        {}
      )

      filter.filter_text_for_content(blog, 'input text', nil)
    end

    it 'includes additional filters from the filter record' do
      filter = TextFilter.new(name: 'test', markup: 'markdown', filters: [:smartypants], params: { key: 'value' })
      allow(TextFilter).to receive(:filter_text).and_return('filtered text')

      expect(TextFilter).to receive(:filter_text).with(
        blog,
        'input text',
        nil,
        [:macropre, 'markdown', :macropost, :smartypants],
        { key: 'value' }
      )

      filter.filter_text_for_content(blog, 'input text', nil)
    end
  end

  describe '#help' do
    let(:blog) { Factory(:blog) }
    let(:filter) { TextFilter.find_by(name: 'markdown') || Factory(:markdown) }

    before do
      allow(TextFilter).to receive(:filters_map).and_return({
        'markdown' => double(
          help_text: 'Markdown help',
          display_name: 'Markdown',
          short_name: 'markdown'
        )
      })
      allow(TextFilter).to receive(:available_filter_types).and_return({
        'macropre' => [],
        'macropost' => []
      })
    end

    it 'returns help text for the filter' do
      filter.filters = []
      help = filter.help
      help.should be_a(String)
    end

    it 'includes help from markup filter' do
      markup_filter = double(help_text: 'Markup help', display_name: 'Markup')
      allow(TextFilter).to receive(:filters_map).and_return({ filter.markup => markup_filter })
      allow(TextFilter).to receive(:available_filter_types).and_return({
        'macropre' => [],
        'macropost' => []
      })
      filter.filters = []

      help = filter.help
      help.should include('Markup')
    end

    it 'returns empty string for filters with blank help text' do
      markup_filter = double(help_text: '', display_name: 'Empty')
      allow(TextFilter).to receive(:filters_map).and_return({ filter.markup => markup_filter })
      allow(TextFilter).to receive(:available_filter_types).and_return({
        'macropre' => [],
        'macropost' => []
      })
      filter.filters = []

      help = filter.help
      help.should_not include('<h3>')
    end
  end

  describe '#commenthelp' do
    let(:blog) { Factory(:blog) }
    let(:filter) { TextFilter.find_by(name: 'markdown') || Factory(:markdown) }

    it 'returns help text for comment filtering' do
      markup_filter = double(help_text: 'Comment help', display_name: 'Markup')
      allow(TextFilter).to receive(:filters_map).and_return({ filter.markup => markup_filter })
      filter.filters = []

      help = filter.commenthelp
      help.should be_a(String)
    end

    it 'includes help from additional filters' do
      markup_filter = double(help_text: 'Markup help')
      smarty_filter = double(help_text: 'Smartypants help')
      allow(TextFilter).to receive(:filters_map).and_return({
        filter.markup => markup_filter,
        'smartypants' => smarty_filter
      })
      filter.filters = ['smartypants']

      help = filter.commenthelp
      help.should include('Smartypants help')
    end

    it 'returns empty string for filters with blank help text' do
      markup_filter = double(help_text: '')
      allow(TextFilter).to receive(:filters_map).and_return({ filter.markup => markup_filter })
      filter.filters = []

      help = filter.commenthelp
      help.strip.should == ''
    end
  end

  describe 'TYPEMAP_NAMES constant' do
    it 'maps filter type names to string keys' do
      TextFilter::TYPEMAP_NAMES.should be_a(Hash)
      TextFilter::TYPEMAP_NAMES['TextFilterPlugin::Markup'].should == 'markup'
      TextFilter::TYPEMAP_NAMES['TextFilterPlugin::MacroPre'].should == 'macropre'
      TextFilter::TYPEMAP_NAMES['TextFilterPlugin::MacroPost'].should == 'macropost'
      TextFilter::TYPEMAP_NAMES['TextFilterPlugin::PostProcess'].should == 'postprocess'
      TextFilter::TYPEMAP_NAMES['TextFilterPlugin'].should == 'other'
    end

    it 'is frozen to prevent modification' do
      TextFilter::TYPEMAP_NAMES.should be_frozen
    end
  end
end
