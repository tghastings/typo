Feature: Admin Login
  As an administrator
  I want to log into the admin panel
  So that I can manage the blog

  Background:
    Given the blog is configured
    And there is an admin user with login "admin" and password "password"

  Scenario: Successful admin login
    When I visit the admin login page
    And I fill in "user_login" with "admin"
    And I fill in "user_password" with "password"
    And I click "Login"
    Then I should see the admin dashboard
    And I should see "Dashboard"

  Scenario: Failed login with wrong password
    When I visit the admin login page
    And I fill in "user_login" with "admin"
    And I fill in "user_password" with "wrongpassword"
    And I click "Login"
    Then I should see "Login unsuccessful"
