require 'spec_helper'

describe "admin/content/new.html.erb" do
  before do
    admin = stub_model(User, :settings => {:editor => 'simple'})
    admin.stub(:admin?) { true }
    admin.stub(:text_filter_name) { "" }
    admin.stub(:profile_label) { "admin" }
    blog = mock_model(Blog, :base_url => "http://myblog.net/")
    article = stub_model(Article)
    article.stub(:new_record?) { true }
    article.stub(:persisted?) { false }
    article.stub(:id) { nil }
    text_filter = stub_model(TextFilter)

    article.stub(:text_filter) { text_filter }
    view.stub(:current_user) { admin }
    view.stub(:this_blog) { blog }

    # FIXME: Nasty. Controller should pass in @categories and @textfilters.
    Category.stub(:all) { [] }
    TextFilter.stub(:all) { [text_filter] }

    # Stub deprecated Rails 2 JavaScript helpers (link_to_remote still used in some views)
    view.stub(:link_to_remote).and_return("")

    assign :article, article
  end

  it "renders with no resources or macros" do
    assign(:images, [])
    assign(:macros, [])
    assign(:resources, [])
    render
  end

  it "renders with image resources" do
    # FIXME: Nasty. Thumbnail creation should not be controlled by the view.
    img = mock_model(Resource, :filename => "foo", :create_thumbnail => nil)
    assign(:images, [img])
    assign(:macros, [])
    assign(:resources, [])
    render
  end
end
