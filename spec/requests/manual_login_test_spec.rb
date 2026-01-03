require 'spec_helper'

RSpec.describe "Manual Login Test", type: :request do
  let!(:blog) { FactoryBot.create(:blog) }
  let!(:admin_profile) { FactoryBot.create(:profile, label: 'admin') }
  let!(:admin_user) { FactoryBot.create(:user, profile: admin_profile, login: 'admin', password: 'password') }

  it "can login via POST to /accounts/login" do
    # First, visit the login page
    get '/accounts/login'
    expect(response).to have_http_status(200)

    # Now POST the login form
    post '/accounts/login', params: {
      user: {
        login: 'admin',
        password: 'password'
      }
    }

    puts "Status: #{response.status}"
    puts "Location: #{response.location}"
    puts "Session user_id: #{session[:user_id]}"

    # Should redirect to admin
    expect(response).to have_http_status(302)
    expect(response).to redirect_to('/admin')
    expect(session[:user_id]).to eq(admin_user.id)
  end

  it "can access admin after login" do
    # Simulate logged in session
    post '/accounts/login', params: {
      user: {
        login: 'admin',
        password: 'password'
      }
    }

    # Follow the redirect
    follow_redirect!

    expect(response).to have_http_status(200)
    expect(request.path).to eq('/admin')
  end
end
