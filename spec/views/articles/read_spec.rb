require 'spec_helper'

describe "articles/read.html.erb" do
  with_each_theme do |theme, view_path|
    describe theme ? "with theme #{theme}" : "without a theme" do
      before(:each) do
        @controller.prepend_view_path(view_path) if theme

        # Stub login helpers for theme layouts that use them
        allow(view).to receive(:logged_in?).and_return(false)
        allow(view).to receive(:current_user).and_return(nil)

        # we do not want to test article links and such
        view.stub(:article_links) { "" }
        view.stub(:category_links) { "" }
        view.stub(:tag_links) { "" }

        view.stub(:display_date_and_time) {|dt| dt.to_s}

        blog = stub_default_blog
        blog.comment_text_filter = "textile"
        @controller.action_name = "redirect"

        article = stub_full_article(Time.now - 2.hours)
        article.body = 'body'
        article.extended = 'extended content'

        @c1 = stub_model(Comment, :created_at => Time.now - 2.seconds, :body => 'Comment body _italic_ *bold*')
        @c2 = stub_model(Comment, :created_at => Time.now, :body => 'Hello foo@bar.com http://www.bar.com')

        article.stub(:published_comments) { [@c1, @c2] }

        text_filter = Factory.build(:textile)
        TextFilter.stub(:find_by_name) { text_filter }

        assign(:article, article)
        render
      end

      it "should not have too many paragraph marks around body" do
        expect(rendered).to have_selector("p", :content => "body")
        expect(rendered).not_to have_selector("p>p", :content => "body")
      end

      it "should not have too many paragraph marks around extended contents" do
        expect(rendered).to have_selector("p", :content => "extended content")
        expect(rendered).not_to have_selector("p>p", :content => "extended content")
      end

      # FIXME: Move comment partial specs to their own spec file.
      it "should not have too many paragraph marks around comment contents" do
        expect(rendered).to have_selector("p>em", :content => "italic")
        expect(rendered).to have_selector("p>strong", :content => "bold")
        expect(rendered).not_to have_selector("p>p>em", :content => "italic")
      end

      it "should automatically add links" do
        rendered.should have_selector("a", :href => "mailto:foo@bar.com",
          :content => "foo@bar.com")
        rendered.should have_selector("a", :href=>"http://www.bar.com",
          :content => "http://www.bar.com")
      end

      it "should show the comment creation times in the comment list" do
        rendered.should =~ /#{@c1.created_at.to_s}/
        rendered.should =~ /#{@c2.created_at.to_s}/
      end
    end
  end
end

