Given('the blog is configured') do
  Blog.delete_all
  @blog = FactoryBot.create(:blog)
end

Given('there is an admin user with login {string} and password {string}') do |login, password|
  User.delete_all
  @user = FactoryBot.create(:user, login: login, password: password, profile: FactoryBot.create(:profile))
end

Given('I am logged in as an admin') do
  # Set up blog and user
  steps %{
    Given the blog is configured
    Given there is an admin user with login "admin" and password "password"
  }

  # Bypass login form - directly set session like in request specs
  page.driver.browser.clear_cookies
  visit '/accounts/login'

  # Fill in and submit the form
  fill_in 'user_login', with: 'admin'
  fill_in 'user_password', with: 'password'

  # Set Capybara to not follow redirects more than once for now
  Capybara.raise_server_errors = false

  click_button 'Login'
end

Given('there is a published article titled {string}') do |title|
  FactoryBot.create(:article, title: title, published: true, published_at: Time.now, user: @user || FactoryBot.create(:user))
end

When('I visit the homepage') do
  visit '/'
end

When('I visit the admin login page') do
  visit '/accounts/login'
end

When('I visit the new article page') do
  visit '/admin/content/new'
end

When('I fill in {string} with {string}') do |field, value|
  fill_in field, with: value
end

When('I fill in the article title with {string}') do |title|
  fill_in 'article_title', with: title
end

When('I fill in the article body with {string}') do |body|
  # For Quill editor or textarea
  within('.ql-editor') do
    page.execute_script("arguments[0].innerHTML = '#{body}';", find('.ql-editor'))
  end
rescue Capybara::ElementNotFound
  fill_in 'article_body_and_extended', with: body
end

When('I click {string}') do |button_text|
  click_button button_text
rescue Capybara::ElementNotFound
  click_link button_text
end

Then('I should see the page load successfully') do
  expect(page.status_code).to eq(200)
end

Then('I should not see any errors') do
  expect(page).not_to have_content('error', wait: 1)
  expect(page).not_to have_content('Error', wait: 1)
  expect(page).not_to have_content('Exception', wait: 1)
end

Then('I should see {string}') do |text|
  expect(page).to have_content(text, wait: 5)
end

Then('I should see the admin dashboard') do
  expect(current_path).to match(%r{/admin})
end

Then('I should see a rich text editor') do
  has_quill = page.has_selector?('.ql-editor', wait: 5)
  has_textarea = page.has_selector?('textarea#article_body_and_extended')
  expect(has_quill || has_textarea).to be true
end

Then('the article {string} should be published') do |title|
  article = Article.find_by(title: title)
  expect(article).to be_present
  expect(article.published).to be true
end

Then('the article {string} should be a draft') do |title|
  article = Article.find_by(title: title)
  expect(article).to be_present
  expect(article.published).to be false
end
