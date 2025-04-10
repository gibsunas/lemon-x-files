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