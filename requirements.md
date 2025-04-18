### Generic Type System

```gherkin
Feature: Generic Type System

  Background:
    Given the following type constraints are defined:
      | Type Parameter | Constraint                | Description                      |
      | T              | Record<string, any>       | Must have string-indexed fields  |
      | K              | keyof T                   | Must be a key of type T          |
      | V              | T extends infer U ? U : never | Inferred type from T        |

  Background:
    Given the following generic type parameters are defined:
      | Parameter | Constraint    | Description                       |
      | T         | any           | Primary data type                 |
      | K         | keyof T       | Keys of type T                    |
      | E         | Error         | Error type extending Error class  |
      | R         | T extends S ? X : Y | Conditional type based on T |

  Scenario Template: Generic Collection Operations <operation>
    Given I have a collection of type "Array<T>"
    When I perform the "<operation>" operation
    Then I should receive a result of type "<resultType>"

    Examples:
      | operation | resultType | description                     |
      | map       | Array<U>   | Transform each item to type U   |
      | filter    | Array<T>   | Subset of original collection   |
      | reduce    | U          | Aggregated value of type U      |
      | find      | T?         | Optional item of type T         |

  Scenario: Using Generic Type with Constraints
    Given I have a generic function with signature "function extract<T, K extends keyof T>(obj: T, key: K)"
    When I call the function with an object of type T and a key of type K
    Then I should receive a return value of type "T[K]"

  Scenario: Modeling relationships between generic types
    Given I have generic types "T" and "U"
    When I define a mapping function between them
    Then the function should have the signature:
    """
    function transform<T, U>(
      input: T, 
      mapper: (value: T) => U
    ): U
    """

  Scenario: Handling unknown type parameters
    Given I have a function that works with any type
    Then it should have the signature:
    """
    function process<*>(input: *): *
    """
    And the "*" should be replaced with appropriate type parameters in implementation
```

### AI Response Formatting and Encoding
```gherkin
Feature: AI Response Formatting and Encoding
  As a user of the AI assistant
  I want to request specific response formats and encodings
  So that I can directly use the output in my applications without manual conversion

  Rule: The assistant must honor explicit formatting and encoding requests when specified in the user's prompt

  Scenario: Requesting JSON formatted responses
    Given I am interacting with the AI assistant
    When I explicitly request JSON formatted output in my prompt
      """
      Example: "Generate a JSON object representing a user profile with name, age, and interests"
      """
    Then The assistant should provide a properly structured JSON response

  Scenario: Requesting XML element responses
    Given I am updating an XML document
    When I ask the assistant to format the response as an XML element
      """
      Example: "Create an XML element for a product with id, name, price, and description attributes"
      """
    Then The assistant should provide a properly formatted XML element

  Scenario: Requesting encoded parameters
    Given I need parameters in a specific encoding format
    When I request URL-safe or Base64 encoded parameters
      """
      Example: "Encode this text as URL-safe: 'Hello World & Special Characters!'"
      Example: "Convert this data to Base64 encoding: 'Sensitive information 123'"
      """
    Then The assistant should provide the parameters in the requested encoding format
    And The encoding should be correctly implemented according to the specified standard

```

### Even more specific 

```gherkin
Feature: Complex Data Transformation and Formatting
  As a developer working with multiple data formats
  I want to transform data through multiple encoding steps
  So that I can integrate with complex systems requiring specific data formats

  Rule: The assistant must be able to perform multi-step data transformations when requested

    Background:
      Given I am working with a system that requires complex data transformations
      And I am interacting with the AI assistant

    Scenario Outline: Transform UUID through multiple formats
      When I request to transform a UUID through the following steps:
        | Source Format | Target Format | Container    |
        | UUID          | <encoding>    | <container>  |
      And I specify the final output format as <output_format>
      Then The assistant should generate a valid UUID
      And Transform it to the specified <encoding>
      And Wrap it in the specified <container>
      And Return the result in the specified <output_format>
      And The final output should be properly structured and parseable

      Examples:
        | encoding | container     | output_format |
        | Base64   | XML element   | JSON          |
        | Hex      | XML attribute | YAML          |
        | Base64   | HTML tag      | JSON          |

    Scenario: UUID to Base64 to XML to JSON with specific element names
      When I request the following transformation:
      """
      Generate a UUID, convert it to Base64, wrap it in an XML element named 'encodedId', 
      and return the result inside a JSON object with a key called 'payload'
      """
      Then The assistant should perform all transformation steps in sequence
      And The final JSON should contain a key named "payload"
      And The value should be an XML string with an "encodedId" element
      And The "encodedId" element should contain a valid Base64-encoded UUID

    Scenario: Multiple UUIDs with different transformations
      When I request multiple UUIDs with different transformations:
        | ID Name  | Encoding | Container    | Output Key |
        | userId   | Base64   | XML element  | user       |
        | sessionId| Hex      | JSON property| session    |
        | requestId| Base64url| HTML div     | request    |
      Then The assistant should generate distinct UUIDs for each row
      And Apply the specified transformations to each UUID
      And Combine all results into a single JSON response
      And Each output key should contain its properly transformed value

    Scenario: Transform Gherkin to TypeScript
      When I provide a Gherkin feature file
      And I request it to be converted to TypeScript test code
      Then The assistant should generate TypeScript code that implements the Gherkin scenarios
      And The TypeScript code should include appropriate test framework syntax
      And Each Gherkin step should be mapped to a corresponding TypeScript function
      And The generated code should maintain the testing intent of the original Gherkin

    Scenario: Transform TypeScript to Gherkin
      When I provide TypeScript test code
      And I request it to be converted to Gherkin format
      Then The assistant should generate valid Gherkin syntax
      And The Gherkin should include appropriate Feature, Scenario, and Step definitions
      And The generated Gherkin should preserve the testing logic from the TypeScript
      And The Gherkin output should follow standard Given-When-Then structure where appropriate

```





### Best Practices (2025)

```gherkin
Feature: Web Development Best Practices 2025
  As a web developer using Create-React-App
  I want to follow industry best practices
  So that my applications are secure, performant, and user-friendly

  Rule: Pages must load within 3 seconds
    Why: Users abandon sites that load slowly, directly impacting conversion rates and SEO rankings

    Scenario: User visits website on mobile device
      Given the user has a 4G connection
      When they navigate to any page on the website
      Then the page should load completely within 3 seconds
      And interactive elements should be responsive immediately

  Rule: Implement AI-driven personalization
    Why: In 2025, users expect websites to anticipate their needs and provide personalized experiences

    Scenario: Returning user visits website
      Given a user has previously interacted with the website
      When they return to the site
      Then the content should adapt based on their previous behavior
      And recommendations should be tailored to their preferences

  Rule: Implement robust security measures following OWASP Top 10
    Why: OWASP guidelines protect against common vulnerabilities that could lead to data breaches

    Scenario: Protecting against injection attacks
      Given a form accepts user input
      When malicious code is entered
      Then the input should be sanitized
      And the attack should be logged and blocked

  Rule: Ensure mobile-first responsive design
    Why: Mobile traffic dominates web usage in 2025, and Google's mobile-first indexing affects SEO rankings

    Scenario: Website viewed on multiple devices
      Given a user accesses the website on devices of different screen sizes
      When they interact with any component
      Then the layout should adapt appropriately to each screen size
      And all functionality should remain accessible

  Rule: Implement proper CORS policies
    Why: CORS prevents unauthorized cross-origin requests, protecting against cross-site scripting attacks

    Scenario: API receives cross-origin request
      Given an API endpoint exists
      When it receives a request from an unauthorized origin
      Then the request should be rejected
      And appropriate CORS headers should be returned

  Rule: Optimize for search engines and web crawlers
    Why: Proper SEO optimization ensures visibility in search results and drives organic traffic

    Scenario: Googlebot crawls React application
      Given a React SPA with client-side rendering
      When Googlebot crawls the application
      Then all content should be properly indexed
      And semantic HTML should provide context for content

  Rule: Implement DDoS protection measures
    Why: DDoS attacks can take down websites, causing downtime and revenue loss

    Scenario: Website experiences traffic spike
      Given the website receives abnormal traffic volume
      When the traffic pattern matches known attack signatures
      Then rate limiting should be applied
      And legitimate users should still be able to access the site

  Rule: Ensure accessibility compliance (WCAG 2.2)
    Why: Accessibility is both a legal requirement and ensures all users can access content regardless of disabilities

    Scenario: Screen reader user navigates website
      Given a user with visual impairment uses a screen reader
      When they navigate through the website
      Then all content should be properly announced
      And interactive elements should be operable via keyboard

  Rule: Implement proper TypeScript typing in React components
    Why: Strong typing reduces runtime errors and improves code maintainability

    Scenario: Developer creates new React component
      Given a new component is being developed
      When props are passed to the component
      Then all props should have explicit TypeScript interfaces
      And component state should be properly typed

  Rule: Optimize performance with modern JavaScript techniques
    Why: Performance optimization directly impacts user experience and conversion rates

    Scenario: Developer implements code optimizations
      Given a React application with performance bottlenecks
      When the developer applies ES2025 features and minimizes render-blocking scripts
      Then the application should load faster
      And user interactions should be more responsive

  Rule: Implement continuous integration and testing
    Why: Automated testing ensures code quality and prevents regressions

    Scenario: New feature is developed
      Given a developer creates a new feature
      When they submit a pull request
      Then automated tests should run
      And code quality checks should be performed before merging

  Rule: Comply with digital privacy regulations
    Why: Privacy laws like GDPR and newer 2025 regulations require strict data protection measures

    Scenario: User data is collected
      Given a website collects personal information
      When a user submits their data
      Then proper consent should be obtained
      And data should be stored with encryption and security safeguards

```