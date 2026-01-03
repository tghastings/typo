require 'spec_helper'

describe ThemeController do
  render_views

  before(:each) { Factory(:blog) }

  it "serves stylesheets from theme" do
    get :stylesheets, :filename => "application.css"
    expect(response).to be_successful
    expect(@response.content_type).to eq("text/css; charset=utf-8")
    expect(@response.charset).to eq("utf-8")
    expect(@response.headers['Content-Disposition']).to include('inline')
  end

  it "serves images from theme" do
    get :images, :filename => "background.gif"
    expect(response).to be_successful
    expect(@response.content_type).to eq("image/gif")
    expect(@response.headers['Content-Disposition']).to include('inline')
  end

  it "rejects malicious paths" do
    get :stylesheets, :filename => "../../../config/database.yml"
    expect(response).to have_http_status(404)
  end

  it "returns 404 for non-existent files" do
    get :stylesheets, :filename => "nonexistent.css"
    expect(response).to have_http_status(404)
  end
end
