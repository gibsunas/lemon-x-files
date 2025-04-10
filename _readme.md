# TypeScript-Gherkin Conversion README

This README provides guidance on translating between TypeScript interfaces and Gherkin scenarios while preserving type information.

## Generic Prompts for TypeScript-Gherkin Conversions

### 0. First Pass (Refined from Claude 3.7 Conversation)

```
I'm working on translating between TypeScript interfaces and Gherkin scenarios while preserving type information. 
I've included some initial background that I'd like you to use to help with this two-way conversion please:

1. First, convert this TypeScript interface to a Gherkin feature/scenario that captures the structural and type information:

`ts
// Base pagination type
interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
}
`

2. Then, show me how to convert the Gherkin back to TypeScript while preserving as much type information as possible. Demonstrate how to infer specific types (numbers, booleans, arrays, generics) from the natural language descriptions in the Gherkin.

3. Explain your reasoning for each type inference and identify any information that cannot be fully preserved in the conversion process.

Please focus on maintaining maximum fidelity between the two formats, recognizing that Gherkin is behavior-focused while TypeScript is structure-focused.
```

### 1. TypeScript to Gherkin Conversion Prompt

```
Convert the following TypeScript interface/type definition to a Gherkin feature that preserves all structural and type information. Focus on representing the types, constraints, and relationships accurately in Gherkin format.

TypeScript:

// Paste your TypeScript interface/type here

Please provide only the Gherkin representation without additional explanation.
```

### 2. Gherkin to TypeScript Conversion Prompt

```
Convert the following Gherkin feature to TypeScript interface(s)/type(s) that preserve all structural and type information. Infer appropriate TypeScript types from the natural language descriptions and ensure the resulting TypeScript is properly documented.

Gherkin:
`gherkin
# Paste your Gherkin feature here
`

Please provide only the TypeScript representation without additional explanation.
```

### 3. Conversion Analysis Prompt

```
I'm working on translating between TypeScript and Gherkin to maintain type information across both formats. Please analyze the following TypeScript and its Gherkin representation (or vice versa) and explain:

1. What information is fully preserved in the conversion
2. What information is partially preserved or transformed
3. What information is lost completely
4. How the conversion could be improved to maintain maximum fidelity

TypeScript:
`typescript
// Paste your TypeScript here
`

Gherkin:
`gherkin
# Paste your Gherkin here
`

Focus on type information, constraints, relationships between types, and how well the semantic meaning transfers between the two formats.
```

## Generic Type System in Gherkin

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

## AI Response Formatting and Encoding

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

## Complex Data Transformation and Formatting

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

## Improved Generic Type Representation in Gherkin

```gherkin
Feature: Generic Type System

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
```

### TypeScript Equivalent

```typescript
/**
* Generic collection operations
* @template T Primary data type
* @template U Result type for transformations
* @template K Keys of type T
*/

// Map operation: Transform each item to type U
function map<T, U>(collection: Array<T>, transformer: (item: T) => U): Array<U>;

// Filter operation: Create subset of original collection
function filter<T>(collection: Array<T>, predicate: (item: T) => boolean): Array<T>;

// Reduce operation: Aggregate to value of type U
function reduce<T, U>(collection: Array<T>, reducer: (accumulator: U, item: T) => U, initial: U): U;

// Find operation: Get optional item of type T
function find<T>(collection: Array<T>, predicate: (item: T) => boolean): T | undefined;

// Extract function with constrained generic types
function extract<T, K extends keyof T>(obj: T, key: K): T[K];
```

## Type Constraints with Background

```gherkin
Background:
  Given the following type constraints are defined:
    | Type Parameter | Constraint                | Description                      |
    | T              | Record<string, any>       | Must have string-indexed fields  |
    | K              | keyof T                   | Must be a key of type T          |
    | V              | T extends infer U ? U : never | Inferred type from T        |
```

## Generic Type Relationships

```gherkin
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
```

## Higher-Order Generic Types

```gherkin
Scenario: Working with higher-order generic types
  Given I have a "Container<T>" generic type
  When I need to transform the contained value
  Then I should use a function with signature:
    """
    function transformContainer<T, U>(
      container: Container<T>,
      transformer: (value: T) => U
    ): Container<U>
    """
```

## Wildcards for Unknown Types

```gherkin
Scenario: Handling unknown type parameters
  Given I have a function that works with any type
  Then it should have the signature:
    """
    function process<*>(input: *): *
    """
  And the "*" should be replaced with appropriate type parameters in implementation
```

## Benefits of This Approach

### Type Parameter Documentation:
- The Background section defines all generic parameters and their constraints
- Each parameter can have a description explaining its purpose

### Relationship Modeling:
- Clearly shows how different generic types relate to each other
- Captures constraints between type parameters

### Parameterized Scenarios:
- Scenario Templates allow testing the same behavior with different types
- Examples tables can show different type combinations

### Conditional Types:
- Can represent basic conditional type relationships
- Shows type inference patterns

## Limitations That Remain

Despite these improvements, some TypeScript generic features remain challenging to represent:

### Complex Type Manipulations:
- TypeScript's utility types like Partial<T>, Required<T>, etc. are difficult to express
- Mapped and indexed access types need verbose descriptions

### Recursive Types:
- Self-referential generic types are hard to represent clearly

### Variadic Generics:
- TypeScript 4.0+ tuple types with spread operators don't have a natural Gherkin equivalent

The most effective approach is to use the Background section to establish the generic type system and then reference these types consistently throughout your scenarios. This creates a "type vocabulary" that can be used across the entire feature file.

## Gherkin Challenges Upfront

### Type Inference and Preservation Analysis

#### Type Inference Process
- **Generic Type (T):**
    - Gherkin Representation: Used the Background section to establish that a generic type exists
    - Inference Back: The generic type parameter <T> was preserved through explicit mention in the table

- **Array Type (items: T[]):**
    - Gherkin Representation: Described as "Array<T>" in the table
    - Inference Back: The array type was inferred from both the type column ("Array<T>") and the description

- **Numeric Types (total, page, pageSize):**
    - Gherkin Representation: Described as "Number" in the table
    - Inference Back: These were correctly inferred as number types in TypeScript

- **Boolean Type (hasMore):**
    - Gherkin Representation: Described as "Boolean" in the table
    - Inference Back: This was correctly inferred as a boolean type

#### Information Preservation Challenges

- **Type Constraints:**
    - Not Preserved: TypeScript can specify constraints on generics (e.g., <T extends BaseEntity>), but this cannot be fully expressed in Gherkin's natural language format

- **Optional Properties:**
    - Not Applicable Here: The original interface didn't have optional properties, but if it did (using ?), this would be difficult to express precisely in Gherkin

- **Union Types:**
    - Not Applicable Here: The original interface didn't have union types, but representing complex types like string | number would require verbose descriptions in Gherkin

- **Default Values:**
    - Not Preserved: TypeScript can specify default values for interface properties in implementations, which isn't captured in the interface definition or the Gherkin

- **Documentation:**
    - Enhanced: The Gherkin format actually adds more context through its scenario descriptions and purpose statements that aren't present in the TypeScript interface

The Gherkin representation successfully captures the structural information and basic types while adding behavioral context, but it cannot fully represent more advanced TypeScript type features like conditional types or mapped types.

## Gherkin Examples Using TypeScript Sources

### Prompt Template

```
I'm working on translating between TypeScript interfaces and Gherkin scenarios while preserving type information. Please help me with this two-way conversion:

1. First, convert this TypeScript interface to a Gherkin feature/scenario that captures the structural and type information:

[PASTE TYPESCRIPT CODE HERE]

2. Then, show me how to convert the Gherkin back to TypeScript while preserving as much type information as possible. Demonstrate how to infer specific types (numbers, booleans, arrays, generics) from the natural language descriptions in the Gherkin.

3. Explain your reasoning for each type inference and identify any information that cannot be fully preserved in the conversion process.

Please focus on maintaining maximum fidelity between the two formats, recognizing that Gherkin is behavior-focused while TypeScript is structure-focused.
```

### Pagination Example

TypeScript:
```typescript
// Base pagination type
interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
}
```

Initial Gherkin attempt:
```gherkin
Feature: Paginated Response Structure

  Scenario: Handling a paginated response
    Given a collection of items of type T
    And a total count of all available items
    And the current page number
    And the page size
    And information about whether more items exist
    Then the response should contain all these properties
    And the items should be accessible as an array
```

Refined Gherkin:
```gherkin
Feature: Paginated Response Structure
  As a developer
  I want to work with paginated data responses
  So that I can efficiently handle large datasets

  Background:
    Given a generic type T exists for the response items

  Scenario: Retrieving a paginated response
    When I request a paginated collection of type T
    Then I should receive a response with the following structure:
      | Field    | Type      | Description                                  |
      | items    | Array<T>  | Collection of items of type T                |
      | total    | Number    | Total count of all available items           |
      | page     | Number    | Current page number                          |
      | pageSize | Number    | Number of items per page                     |
      | hasMore  | Boolean   | Flag indicating if more pages are available  |

  Scenario Outline: Validating pagination properties
    Given a paginated response of type T
    When I check the "<property>" property
    Then it should be of type "<type>"

    Examples:
      | property | type    |
      | items    | Array   |
      | total    | Number  |
      | page     | Number  |
      | pageSize | Number  |
      | hasMore  | Boolean |
```

### Search Params Example

TypeScript:
```typescript
// Request params
interface SearchParams {
  query: string;
  page?: number;
  limit?: number;
  sort?: 'asc' | 'desc';
}
```

Gherkin:
```gherkin
Feature: Search Parameters

  Scenario: Basic search with required parameters
    Given a search query string
    Then the search can be performed

  Scenario: Search with optional pagination
    Given a search query string
    And an optional page number
    And an optional limit of results
    Then the search returns the specified page with the specified limit

  Scenario: Search with sorting
    Given a search query string
    And an optional sort direction of either "asc" or "desc"
    Then the search results are sorted accordingly
```

### API Error Example

TypeScript:
```typescript
// API error
interface ApiError {
  code: string;
  message: string;
  details?: Record<string, unknown>;
}
```

Gherkin:
```gherkin
Feature: API Error Handling

  Scenario: Handling a basic API error
    Given an error code string
    And an error message string
    Then the error can be properly identified and communicated

  Scenario: Handling an API error with details
    Given an error code string
    And an error message string
    And optional additional details as key-value pairs
    Then the error can be properly identified with contextual information
```

### API Function Example

TypeScript:
```typescript
// Combine them
async function searchApi<T>(
  params: SearchParams
): Promise<PaginatedResponse<T> | ApiError> {
  // Implementation
}
```

Gherkin:
```gherkin
Feature: Search API Function

  Scenario: Successful search request
    Given valid search parameters
    When the search API is called
    Then it returns a paginated response of items

  Scenario: Failed search request
    Given invalid or problematic search parameters
    When the search API is called
    Then it returns an API error with appropriate code and message
```

