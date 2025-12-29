require 'spec_helper'

describe ThemeController do
  render_views

  before(:each) { Factory(:blog) }

  it "test_stylesheets" do
    get :stylesheets, :filename => "style.css"
    expect(response).to be_successful
    expect(@response.content_type).to eq("text/css; charset=utf-8")
    expect(@response.charset).to eq("utf-8")
    expect(@response.headers['Content-Disposition']).to match(/inline; filename="style.css"/)
  end

  it "test_images" do
    get :images, :filename => "bg_white.png"
    expect(response).to be_successful
    expect(@response.content_type).to eq("image/png")
    expect(@response.headers['Content-Disposition']).to match(/inline; filename="bg_white.png"/)
  end

  it "test_malicious_path" do
    get :stylesheets, :filename => "../../../config/database.yml"
    expect(response).to have_http_status(404)
  end

  it "test_view_theming" do
    get :static_view_test
    expect(response).to be_successful

    expect(@response.body =~ /Static View Test from typographic/).to be_truthy
  end

  it "disabled_test_javascript"
  if false
    get :stylesheets, :filename => "typo.js"
    expect(response).to be_successful
    expect(@response.content_type).to eq("text/javascript")
    expect(@response.headers['Content-Disposition']).to eq("inline; filename=\"typo.js\"")
  end
end
