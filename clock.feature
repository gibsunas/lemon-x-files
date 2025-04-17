Feature: Server Monitoring
  As a system administrator
  I want to monitor the health of the server
  So that I can ensure it's functioning properly

  Background:
    Given the server has health monitoring middleware enabled

  Scenario Outline: Health endpoint responses
    When a client makes a <requestType> request to "/<endpoint>"
    Then the server should respond with status <statusCode>
    And the response should include <responseContent>

    Examples:
      | requestType | endpoint | statusCode | responseContent           |
      | GET         | health   | 200        | server uptime information |
      | GET         | metrics  | 200        | performance metrics       |
      | POST        | health   | 405        | method not allowed error  |

Feature: Error Handling
  As a developer
  I want proper server error handling
  So that clients receive meaningful error messages

  Background:
    Given the server has error validation middleware configured

  Scenario Outline: Handle different types of GraphQL queries
    When a client sends a "<queryType>" query
    Then the server should respond with status code <statusCode>
    And the response should contain <responseType>
    And the error should be <loggingBehavior>

    Examples:
      | queryType             | statusCode | responseType                   | loggingBehavior       |
      | valid                 | 200        | requested data                 | not logged            |
      | malformed             | 400        | detailed error information     | logged on the server  |
      | unauthorized resource | 403        | permission denied message      | logged with user info |
      | server error trigger  | 500        | generic error message          | logged with full trace|

Feature: API Security
  As a system administrator
  I want to secure the GraphQL API
  So that only authorized clients can access it

  Background:
    Given the application server includes JWT authentication middleware

  Scenario Outline: Authentication and rate limiting
    Given the server has <securityFeature> configured to <configValue>
    When a client <clientAction>
    Then the server should respond with status <statusCode>
    And the response should include <responseHeader>

    Examples:
      | securityFeature    | configValue              | clientAction                        | statusCode | responseHeader                    |
      | basic authentication | "API-Key required"     | makes a request without credentials | 401        | error message "Authentication required" |
      | JWT validation     | "10 minute expiry"       | uses an expired token               | 401        | error message "Token expired"      |
      | rate limiting      | 100 requests per minute  | exceeds the allowed request rate    | 429        | "Retry-After" header              |
      | CORS protection    | "trusted-domain.com"     | requests from untrusted domain      | 403        | error message "Origin not allowed" |

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
Feature: GraphQL Schema Definition and Management
  As a developer
  I want to define and maintain a proper GraphQL schema in a federated mesh API
  So that clients can query for time data and other services reliably

  Background:
    Given the server has a GraphQL schema definition file
    And the schema is registered in the federated mesh API gateway



  Scenario: Schema validation timing
    When a new schema version is submitted
    Then validation checks should run during the CI/CD pipeline
    And validation checks should run before deployment to any environment
    And validation checks should run as part of the gateway composition process
    And schema compatibility with existing clients should be verified


  Scenario Outline: Schema authorization for different user roles
    Given a user with role "<role>" wants to examine the schema
    When they request the schema through introspection
    Then they should have valid authentication credentials
    And they should <permission_requirement> the "<required_permission>" permission
    And sensitive field descriptions should be <redaction_level> based on their role
    And the introspection query depth should be limited to <max_depth> levels for security
    And they should <access_type> to fields marked with "<sensitivity_level>" sensitivity

    Examples:
      | role          | permission_requirement | required_permission | redaction_level | max_depth | access_type      | sensitivity_level |
      | anonymous     | not have access to     | schema:read         | fully redacted  | 1         | have no access   | public            |
      | basic_user    | have                   | schema:read         | partially redacted | 2      | have no access   | internal          |
      | developer     | have                   | schema:read         | minimally redacted | 3      | have read access | internal          |
      | admin         | have                   | schema:admin        | not redacted    | 5         | have full access | internal          |
      | security_team | have                   | schema:admin        | not redacted    | unlimited | have full access | sensitive         |


  Scenario Outline: Schema examples for different GraphQL components
    When a developer examines the schema documentation for "<component_type>"
    Then the documentation should include <example_count> usage examples
    And examples should demonstrate <functionality_type>
    And examples should include <error_handling> error handling patterns
    And examples should be written in <format> format
    And examples should include <advanced_feature> when applicable

    Examples:
      | component_type | example_count | functionality_type           | error_handling        | format                | advanced_feature             |
      | complex types  | at least 2    | field access and nesting     | null value handling   | JSON                  | type interfaces              |
      | queries        | at least 3    | common operations            | error code responses  | GraphQL query syntax  | filtering and sorting        |
      | mutations      | at least 3    | proper input formatting      | validation errors     | GraphQL mutation syntax | optimistic responses       |
      | subscriptions  | at least 2    | event handling               | reconnection patterns | GraphQL subscription  | backpressure handling        |
      | list types     | at least 2    | pagination                   | empty results         | cursor-based examples | infinite scrolling           |
      | federated types| at least 3    | cross-service references     | partial results       | entity resolution     | distributed transaction flow |

  Scenario Outline: Schema validation for different GraphQL components
    When the GraphQL schema is loaded with "<component>" definitions
    Then the schema should be validated without errors
    And the schema should define <required_elements>
    And the component should return <expected_return_type>
    And the schema should conform to <specification_version>
    And the schema should include <federation_requirements>
    And <directive_requirements> directives should be present

    Examples:
      | component      | required_elements                 | expected_return_type     | specification_version    | federation_requirements       | directive_requirements                 |
      | queries        | a "serverTime" query              | String type              | federation specification v2 | proper entity references    | @key, @external for shared entities   |
      | mutations      | proper input and payload types    | appropriate result types | federation specification v2 | transaction boundaries      | @requires, @provides where needed     |
      | subscriptions  | proper event stream handling      | subscription types       | federation specification v2 | service ownership metadata  | @stream for real-time data            |
      | types          | proper field definitions          | scalar or object types   | federation specification v2 | proper entity keys          | @extends for type extensions          |
      | interfaces     | consistent implementation fields  | implementable contracts  | federation specification v2 | cross-service interfaces    | @interfaceObject for federation       |
      | enums          | all possible values               | enum values              | federation specification v2 | consistent enum definitions | @shareable for multi-service enums    |

  Scenario Outline: Schema documentation for different GraphQL components
    When the GraphQL schema "<component>" is examined
    Then <description_requirement> should have a description
    And the description should be <description_quality> with <description_length> characters
    And <example_requirement> should be documented with usage examples
    And <directive_documentation> should be documented
    And <deprecation_documentation> should include migration paths
    And <constraint_documentation> should document its constraints

    Examples:
      | component      | description_requirement | description_quality | description_length | example_requirement       | directive_documentation              | deprecation_documentation       | constraint_documentation        |
      | fields         | each field              | clear and concise   | at least 20        | complex fields            | field-level directives              | deprecated fields               | nullability constraints        |
      | types          | each type               | detailed            | at least 50        | all custom types          | type-level directives               | deprecated types                | validation rules               |
      | queries        | each query              | comprehensive       | at least 100       | the "serverTime" query    | query-specific directives           | deprecated queries              | performance constraints        |
      | mutations      | each mutation           | step-by-step        | at least 150       | all mutations             | mutation-specific directives        | deprecated mutations            | input validation constraints   |
      | subscriptions  | each subscription       | event-focused       | at least 100       | all subscriptions         | subscription-specific directives    | deprecated subscriptions        | rate limiting constraints      |
      | directives     | each directive          | usage-oriented      | at least 80        | federation directives     | federation-specific directives      | deprecated directives           | application constraints        |

  Scenario: Schema field statistics
    When an administrator views the schema analytics dashboard
    Then they should see query frequency statistics for each field
    And they should see average response time for each resolver
    And they should see error rates for each field
    And they should see field usage patterns across different clients
    And they should see field deprecation compliance metrics
    And statistics should be filterable by time period and client

  Scenario: Schema federation capabilities
    When the schema is composed in the gateway
    Then entity references should resolve across service boundaries
    And the schema should define proper extension points for other services
    And the schema should include @key directives for entity identification
    And the schema should handle distributed transactions appropriately
    And the schema should include proper versioning strategies

Feature: Node.js GraphQL Server Initialization
  As a developer
  I want to properly initialize a GraphQL server
  So that it can handle client requests reliably

  Background:
    Given the server is built with Node.js
    And the server implements a GraphQL API
    And the server has a valid configuration file

  Rule: Server must start within a reasonable timeframe
    Scenario: Server startup
      Given the environment variables are properly set
      When the server application is started
      Then the GraphQL endpoint should be available at "/graphql"
      And the server should log "GraphQL Server running on port 4000"
      And the server should be listening on port 4000
      And the server should start within 5 seconds

  Rule: GraphQL playground must be available in development mode
    Scenario: GraphQL playground availability
      Given the server is running
      And the environment is set to "development"
      When I navigate to the "/graphql" endpoint in a browser
      Then the GraphQL playground should be displayed
      And introspection should be enabled

  Rule: Server must handle termination signals properly
    Scenario: Server graceful shutdown
      Given the server is running
      And there are active client connections
      When the server receives a termination signal
      Then it should complete all pending requests
      And close all database connections
      And release all system resources
      And log "Server shutting down gracefully"
      And exit with code 0

  Rule: Server must handle startup errors appropriately
    Scenario: Error handling during startup
      Given the required port is already in use
      When the server application is started
      Then it should log an appropriate error message
      And exit with a non-zero status code

  Rule: Server must handle database connection failures
    Scenario: Database connection failure
      Given the database connection string is invalid
      When the server application is started
      Then it should retry the connection 3 times
      And log "Database connection failed after 3 attempts"
      And exit with a non-zero status code

  Rule: Server must provide health check endpoint
    Scenario: Health check endpoint
      Given the server is running
      When a GET request is sent to "/health"
      Then the response status code should be 200
      And the response should include server status information

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
