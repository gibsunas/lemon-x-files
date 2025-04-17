Feature: Automated Build, Lint, and Test Pipeline
  As a repository maintainer
  I want automated quality checks on pull requests
  So that code quality is maintained and issues are caught early

  Background:
    Given a GitHub repository
    And a ".github/workflows" directory exists
    And a "blt.yml" workflow file is configured

  Scenario: New pull request triggers quality checks
    When a developer creates a new pull request
    Then the "blt.yml" workflow should automatically trigger
    And the code should be built
    And the code should be linted for style and formatting issues
    And the automated tests should run against the changes

  Scenario: Pull request with failing tests
    When a developer submits code that fails tests
    Then the "blt.yml" workflow should report failure status
    And the pull request should be marked as failing checks
    And the developer should receive feedback about the failures

  Scenario: Pull request with linting issues
    When a developer submits code with style violations
    Then the "blt.yml" workflow should identify the issues
    And report them in the pull request comments
    And require fixes before merging is allowed

  Scenario: Clean pull request passes all checks
    When a developer submits well-formatted code that passes all tests
    Then the "blt.yml" workflow should report success
    And the pull request should be marked as passing all checks
    And the code can be reviewed for merging
