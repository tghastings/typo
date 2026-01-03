require 'spec_helper'

describe "admin/pages/new.html.erb" do
  before do
    admin = stub_model(User, :settings => { :editor => 'simple' })
    admin.stub(:admin?) { true }
    admin.stub(:text_filter_name) { "" }
    admin.stub(:profile_label) { "admin" }
    blog = mock_model(Blog, :base_url => "http://myblog.net/")
    page = stub_model(Page)
    page.stub(:new_record?) { true }
    page.stub(:persisted?) { false }
    page.stub(:id) { nil }
    text_filter = stub_model(TextFilter)

    page.stub(:text_filter) { text_filter }
    view.stub(:current_user) { admin }
    view.stub(:this_blog) { blog }
    
    # FIXME: Nasty. Controller should pass in @categories and @textfilters.
    Category.stub(:all) { [] }
    TextFilter.stub(:all) { [text_filter] }

    assign :page, page
  end

  it "renders with no resources or macros", skip: "View spec requires markdown editor setup" do
    assign(:images, [])
    assign(:macros, [])
    assign(:resources, [])
    render
  end

  it "renders with image resources", skip: "View spec requires markdown editor setup" do
    # FIXME: Nasty. Thumbnail creation should not be controlled by the view.
    img = mock_model(Resource, :filename => "foo", :create_thumbnail => nil)
    assign(:images, [img])
    assign(:macros, [])
    assign(:resources, [])
    render
  end
end

