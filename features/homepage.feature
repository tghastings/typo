Feature: Homepage
  As a visitor
  I want to view the blog homepage
  So that I can see published articles

  Scenario: View empty blog homepage
    Given the blog is configured
    When I visit the homepage
    Then I should see the page load successfully
    And I should not see any errors

  Scenario: View homepage with articles
    Given the blog is configured
    And there is a published article titled "First Post"
    When I visit the homepage
    Then I should see the page load successfully
    And I should see "First Post"
