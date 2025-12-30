Feature: Admin Article Creation
  As an administrator
  I want to create new articles
  So that I can publish content on the blog

  Background:
    Given the blog is configured
    And I am logged in as an admin

  Scenario: Access new article page
    When I visit the new article page
    Then I should see the page load successfully
    And I should see "Write a Post"
    And I should see a rich text editor

  Scenario: Create a new article
    When I visit the new article page
    And I fill in the article title with "My New Post"
    And I fill in the article body with "This is my first blog post"
    And I click "Publish"
    Then I should see "Article was successfully created"
    And the article "My New Post" should be published

  Scenario: Save article as draft
    When I visit the new article page
    And I fill in the article title with "Draft Post"
    And I fill in the article body with "This is a draft"
    And I click "Save as draft"
    Then I should see "Draft was successfully created"
    And the article "Draft Post" should be a draft
