Feature: Server Monitoring
  As a system administrator
  I want to monitor the health of the GraphQL server
  So that I can ensure it's functioning properly

  Background:
    Given the server has monitoring endpoints configured

  Scenario: Health check endpoint
    Given the server has a health check endpoint at "/health"
    When a client makes a GET request to "/health"
    Then the server should respond with status 200
    And the response should include server uptime information

  Scenario: Metrics collection
    Given the server has a metrics endpoint at "/metrics"
    When a client makes a GET request to "/metrics"
    Then the server should respond with performance metrics
    And the metrics should include request count and response times
Feature: Error Handling
  As a developer
  I want proper error handling in the GraphQL API
  So that clients receive meaningful error messages

  Background:
    Given the GraphQL server has error handling middleware

  Scenario: Malformed query handling
    When a client makes a malformed GraphQL query
    Then the server should respond with a 400 Bad Request status
    And the response should include detailed error information
    And the error should be logged on the server

  Scenario: Internal server error handling
    When an unexpected error occurs during query processing
    Then the server should respond with a 500 Internal Server Error
    And the response should not expose sensitive implementation details
    And the full error should be logged for debugging

Feature: API Security
  As a system administrator
  I want to secure the GraphQL API
  So that only authorized clients can access it

  Background:
    Given the server has security middleware configured

  Scenario: API authentication
    Given the server has basic authentication enabled
    When a client makes a request without proper authentication
    Then the server should respond with a 401 Unauthorized status
    And the response should include an error message "Authentication required"

  Scenario: Rate limiting
    Given the server has rate limiting configured to 100 requests per minute
    When a client exceeds the allowed request rate
    Then the server should respond with a 429 Too Many Requests status
    And the response should include a "Retry-After" header
Feature: Server Time Query
  As a client application
  I want to query the server for its current time
  So that I can display it to users

  Background:
    Given the GraphQL server is running
    And the server has a resolver for the "serverTime" query

  Scenario: Basic time query
    When a client makes a GraphQL query:
      """
      {
        serverTime
      }
      """
    Then the server should respond with the current server time
    And the response should be in ISO 8601 format
    And the response time should be less than 100ms

  Scenario: Time query with format parameter
    When a client makes a GraphQL query with a format parameter:
      """
      {
        serverTime(format: "HH:mm:ss")
      }
      """
    Then the server should respond with the time in the requested format
Feature: GraphQL Schema Definition
  As a developer
  I want to define a proper GraphQL schema
  So that clients can query for time data

  Background:
    Given the server has a GraphQL schema definition file

  Scenario: Schema validation
    When the GraphQL schema is loaded
    Then the schema should be validated without errors
    And the schema should define a "serverTime" query
    And the "serverTime" query should return a String type

  Scenario: Schema documentation
    When the GraphQL schema is examined
    Then each field should have a description
    And the "serverTime" query should be documented with usage examples
Feature: Node.js GraphQL Server Initialization
  As a developer
  I want to properly initialize a GraphQL server
  So that it can handle client requests reliably

  Background:
    Given the server is built with Node.js
    And the server implements a GraphQL API

  Scenario: Server startup
    When the server application is started
    Then the GraphQL endpoint should be available at "/graphql"
    And the server should log "GraphQL Server running on port 4000"
    And the server should be listening on port 4000

  Scenario: Server graceful shutdown
    When the server receives a termination signal
    Then it should complete all pending requests
    And close all database connections
    And log "Server shutting down gracefully"

Feature: Time Display Application
  As a user
  I want to view both server time and my local time
  So that I can compare the time differences

  Background:
    Given the application is a single page React app
    And the backend is a Node.js GraphQL API

  Scenario: Loading the application
    When I navigate to the application URL
    Then I should see a single page application load
    And the page should display a title "Time Display"

  Scenario: Viewing server time
    When the application loads
    Then the application should make a GraphQL query to fetch server time
    And I should see the server time displayed in the format "HH:MM:SS"
    And the server time should update every second

  Scenario: Viewing local time
    When the application loads
    Then the application should calculate my local time
    And I should see my local time displayed in the format "HH:MM:SS"
    And my local time should update every second

  Scenario: Time comparison
    When both server time and local time are displayed
    Then I should be able to visually compare the two times
    And if there is a time difference, it should be clearly indicated

  Scenario: GraphQL API connection failure
    Given the GraphQL API is unavailable
    When I load the application
    Then I should see an error message "Unable to connect to server"
    And the application should attempt to reconnect automatically
    And my local time should still be displayed correctly

  Scenario: Responsive design
    When I view the application on different screen sizes
    Then the time displays should adjust to fit the screen
    And all information should remain visible and readable
