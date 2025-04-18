# Creating a fluid syntax for easy use internally
> DevNote: Because the libraries in use are so technically deep
>          until a better solution is discovered lets build our
>          own..... please let this not suck
## Initial reference material
```ts
import { Feature, Background, Scenario, ScenarioTemplate, Examples, Step, DataTable } from 'gherkin-ast';

// Type definitions for the generic type system
interface GenericTypeParameter {
  parameter: string;
  constraint: string;
  description: string;
}

interface OperationExample {
  operation: string;
  resultType: string;
  description: string;
}

// Create the feature using the builder pattern
const genericTypeSystemFeature = new Feature('Generic Type System')
  .addBackground(new Background()
    .addStep(new Step('Given', 'the following generic type parameters are defined:')
      .withDataTable(new DataTable([
        ['Parameter', 'Constraint', 'Description'],
        ['T', 'any', 'Primary data type'],
        ['K', 'keyof T', 'Keys of type T'],
        ['E', 'Error', 'Error type extending Error class'],
        ['R', 'T extends S ? X : Y', 'Conditional type based on T']
      ]))
    )
  )
  .addScenarioTemplate(new ScenarioTemplate('Generic Collection Operations <operation>')
    .addStep(new Step('Given', 'I have a collection of type "Array<T>"'))
    .addStep(new Step('When', 'I perform the "<operation>" operation'))
    .addStep(new Step('Then', 'I should receive a result of type "<resultType>"'))
    .addExamples(new Examples()
      .withDataTable(new DataTable([
        ['operation', 'resultType', 'description'],
        ['map', 'Array<U>', 'Transform each item to type U'],
        ['filter', 'Array<T>', 'Subset of original collection'],
        ['reduce', 'U', 'Aggregated value of type U'],
        ['find', 'T?', 'Optional item of type T']
      ]))
    )
  )
  .addScenario(new Scenario('Using Generic Type with Constraints')
    .addStep(new Step('Given', 'I have a generic function with signature "function extract<T, K extends keyof T>(obj: T, key: K)"'))
    .addStep(new Step('When', 'I call the function with an object of type T and a key of type K'))
    .addStep(new Step('Then', 'I should receive a return value of type "T[K]"'))
  );

// Actual TypeScript interfaces/types that would represent the concepts in the Gherkin feature
// These would be used in the actual implementation

// Generic type parameters as described in the Background
type PrimaryDataType<T = any> = T;
type KeysOfType<T> = keyof T;
type ErrorType = Error;
type ConditionalType<T, S, X, Y> = T extends S ? X : Y;

// Generic collection operations as described in the Scenario Template
interface GenericCollection<T> {
  map<U>(callback: (item: T) => U): Array<U>;
  filter(predicate: (item: T) => boolean): Array<T>;
  reduce<U>(reducer: (accumulator: U, current: T) => U, initialValue: U): U;
  find(predicate: (item: T) => boolean): T | undefined;
}

// Generic function with constraints as described in the Scenario
function extract<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}

export {
  genericTypeSystemFeature,
  GenericTypeParameter,
  OperationExample,
  PrimaryDataType,
  KeysOfType,
  ErrorType,
  ConditionalType,
  GenericCollection,
  extract
};

```



## implementation?

```typescript
// gherkin-feature.ts
import {
  Feature, Background, Scenario, ScenarioTemplate, Examples,
  Step, DataTable, DocString, Tag, Rule, Comment, Document
} from 'gherkin-ast';
import { writeFeature } from 'gherkin-io';

/**
 * Interface for defining steps in Gherkin scenarios.
 * 
 * @interface StepDefinition
 * @property {string} keyword - The step keyword ('Given', 'When', 'Then', 'And', 'But')
 * @property {string} text - The step text
 * @property {string[][]} [dataTable] - Optional data table for the step
 * @property {string} [docString] - Optional doc string for the step
 * 
 * @example
 * ```typescript

* const step: StepDefinition = {
*   keyword: &#x27;Given&#x27;,
*   text: &#x27;the following users exist&#x27;,
*   dataTable: [
*     [&#x27;username&#x27;, &#x27;email&#x27;],
*     [&#x27;john&#x27;, &#x27;john@example.com&#x27;],
*     [&#x27;jane&#x27;, &#x27;jane@example.com&#x27;]
*   ]
* };
* ```
 */
export interface StepDefinition {
  keyword: string;
  text: string;
  dataTable?: string[][];
  docString?: string;
}

/**
 * RuleBuilder - A helper class for building Rule objects within a feature.
 * Rules help organize scenarios into logical groups.
 */
export class RuleBuilder {
  private rule: Rule;
  private parent: GherkinFeatureBuilder;

  /**
   * Creates a new rule builder.
   * 
   * @param {GherkinFeatureBuilder} parent - The parent feature builder
   * @param {string} name - The name of the rule
   * @param {string} [description] - Optional description of the rule
   */
  constructor(parent: GherkinFeatureBuilder, name: string, description?: string) {
    this.parent = parent;
    this.rule = new Rule(name);
    if (description) {
      this.rule.withDescription(description);
    }
  }

  /**
   * Adds or updates the rule description.
   * 
   * @param {string} description - The rule description
   * @returns {RuleBuilder} The builder instance for method chaining
   */
  withDescription(description: string): RuleBuilder {
    this.rule.withDescription(description);
    return this;
  }

  /**
   * Adds tags to the rule.
   * 
   * @param {string[]} tags - Array of tags
   * @returns {RuleBuilder} The builder instance for method chaining
   */
  addTags(tags: string[]): RuleBuilder {
    tags.forEach(tag => {
      this.rule.addTag(new Tag(tag));
    });
    return this;
  }

  /**
   * Adds a background section to the rule.
   * 
   * @param {StepDefinition[]} steps - Array of step definitions for the background
   * @returns {RuleBuilder} The builder instance for method chaining
   */
  addBackground(steps: StepDefinition[]): RuleBuilder {
    const background = new Background();

    steps.forEach(step => {
      const newStep = new Step(step.keyword, step.text);
      if (step.dataTable) {
        newStep.withDataTable(new DataTable(step.dataTable));
      }
      if (step.docString) {
        newStep.withDocString(new DocString(step.docString));
      }
      background.addStep(newStep);
    });

    this.rule.addBackground(background);
    return this;
  }

  /**
   * Adds a scenario to the rule.
   * 
   * @param {string} name - The name of the scenario
   * @param {StepDefinition[]} steps - Array of step definitions for the scenario
   * @param {string[]} [tags] - Optional array of tags for the scenario
   * @returns {RuleBuilder} The builder instance for method chaining
   */
  addScenario(name: string, steps: StepDefinition[], tags?: string[]): RuleBuilder {
    const scenario = new Scenario(name);

    if (tags) {
      tags.forEach(tag => {
        scenario.addTag(new Tag(tag));
      });
    }

    steps.forEach(step => {
      const newStep = new Step(step.keyword, step.text);
      if (step.dataTable) {
        newStep.withDataTable(new DataTable(step.dataTable));
      }
      if (step.docString) {
        newStep.withDocString(new DocString(step.docString));
      }
      scenario.addStep(newStep);
    });

    this.rule.addScenario(scenario);
    return this;
  }

  /**
   * Adds a scenario outline to the rule.
   * 
   * @param {string} name - The name of the scenario outline
   * @param {StepDefinition[]} steps - Array of step definitions containing placeholders
   * @param {string[][]} examples - 2D array representing the examples table
   * @param {string[]} [tags] - Optional array of tags for the scenario outline
   * @returns {RuleBuilder} The builder instance for method chaining
   */
  addScenarioOutline(name: string, steps: StepDefinition[], examples: string[][], tags?: string[]): RuleBuilder {
    const scenarioOutline = new ScenarioTemplate(name);

    if (tags) {
      tags.forEach(tag => {
        scenarioOutline.addTag(new Tag(tag));
      });
    }

    steps.forEach(step => {
      const newStep = new Step(step.keyword, step.text);
      if (step.dataTable) {
        newStep.withDataTable(new DataTable(step.dataTable));
      }
      if (step.docString) {
        newStep.withDocString(new DocString(step.docString));
      }
      scenarioOutline.addStep(newStep);
    });

    if (examples && examples.length > 0) {
      const examplesObj = new Examples().withDataTable(new DataTable(examples));
      scenarioOutline.addExamples(examplesObj);
    }

    this.rule.addScenarioTemplate(scenarioOutline);
    return this;
  }

  /**
   * Adds a comment to the rule.
   * 
   * @param {string} text - The comment text
   * @returns {RuleBuilder} The builder instance for method chaining
   */
  addComment(text: string): RuleBuilder {
    this.rule.addComment(new Comment(text));
    return this;
  }

  /**
   * Completes the rule definition and returns to the parent feature builder.
   * 
   * @returns {GherkinFeatureBuilder} The parent feature builder
   */
  done(): GherkinFeatureBuilder {
    // Add the rule to the feature and return the parent builder
    this.parent.build().addRule(this.rule);
    return this.parent;
  }
}

/**
 * GherkinFeatureBuilder - A fluent interface for programmatically creating valid Gherkin feature files.
 * 
 * @example
 * ```typescript
* import { GherkinFeatureBuilder, StepDefinition } from &#x27;./gherkin-feature&#x27;;
* 
* // Create a new feature
* const builder = new GherkinFeatureBuilder(&#x27;Shopping Cart&#x27;, &#x27;As a user, I want to manage my shopping cart&#x27;);
* 
* // Add tags
* builder.addTags([&#x27;@ui&#x27;, &#x27;@cart&#x27;]);
* 
* // Add background steps
* const backgroundSteps: StepDefinition[] = [
*   { keyword: &#x27;Given&#x27;, text: &#x27;the user is logged in&#x27; },
*   { keyword: &#x27;And&#x27;, text: &#x27;the shopping cart is empty&#x27; }
* ];
* builder.addBackground(backgroundSteps);
* 
* // Add a scenario
* const scenarioSteps: StepDefinition[] = [
*   { keyword: &#x27;When&#x27;, text: &#x27;the user adds an item to the cart&#x27; },
*   { keyword: &#x27;Then&#x27;, text: &#x27;the cart should contain 1 item&#x27; }
* ];
* builder.addScenario(&#x27;Adding an item to the cart&#x27;, scenarioSteps, [&#x27;@add-item&#x27;]);
* 
* // Write to file
* builder.writeToFile(&#x27;shopping-cart.feature&#x27;);
* ```
 */
export class GherkinFeatureBuilder {
  private feature: Feature;
  private document: Document;

  /**
   * Creates a new Gherkin feature builder.
   * 
   * @param {string} name - The name of the feature
   * @param {string} [description] - Optional description of the feature
   */
  constructor(name: string, description?: string) {
    this.feature = new Feature(name);
    if (description) {
      this.feature.withDescription(description);
    }
    this.document = new Document();
    this.document.addFeature(this.feature);
  }

  /**
   * Adds or updates the feature description.
   * 
   * @param {string} description - The feature description
   * @returns {GherkinFeatureBuilder} The builder instance for method chaining
   */
  withDescription(description: string): GherkinFeatureBuilder {
    this.feature.withDescription(description);
    return this;
  }

  /**
   * Adds tags to the feature.
   * 
   * @param {string[]} tags - Array of tags (e.g., ['@ui', '@regression'])
   * @returns {GherkinFeatureBuilder} The builder instance for method chaining
   */
  addTags(tags: string[]): GherkinFeatureBuilder {
    tags.forEach(tag => {
      this.feature.addTag(new Tag(tag));
    });
    return this;
  }

  /**
   * Adds a background section that runs before each scenario.
   * 
   * @param {StepDefinition[]} steps - Array of step definitions for the background
   * @returns {GherkinFeatureBuilder} The builder instance for method chaining
   * 
   * @example
   * ```typescript
* builder.addBackground([
*   { keyword: &#x27;Given&#x27;, text: &#x27;the user is logged in&#x27; },
*   { keyword: &#x27;And&#x27;, text: &#x27;the shopping cart is empty&#x27; }
* ]);
* ```
   */
  addBackground(steps: StepDefinition[]): GherkinFeatureBuilder {
    const background = new Background();

    steps.forEach(step => {
      const newStep = new Step(step.keyword, step.text);
      this.addStepData(newStep, step);
      background.addStep(newStep);
    });

    this.feature.addBackground(background);
    return this;
  }

  /**
   * Adds a scenario to the feature.
   * 
   * @param {string} name - The name of the scenario
   * @param {StepDefinition[]} steps - Array of step definitions for the scenario
   * @param {string[]} [tags] - Optional array of tags for the scenario
   * @returns {GherkinFeatureBuilder} The builder instance for method chaining
   * 
   * @example
   * ```typescript
* builder.addScenario(&#x27;Adding an item to the cart&#x27;, [
*   { keyword: &#x27;When&#x27;, text: &#x27;the user adds an item to the cart&#x27; },
*   { keyword: &#x27;Then&#x27;, text: &#x27;the cart should contain 1 item&#x27; }
* ], [&#x27;@add-item&#x27;]);
* ```
   */
  addScenario(name: string, steps: StepDefinition[], tags?: string[]): GherkinFeatureBuilder {
    const scenario = new Scenario(name);

    if (tags) {
      tags.forEach(tag => {
        scenario.addTag(new Tag(tag));
      });
    }

    steps.forEach(step => {
      const newStep = new Step(step.keyword, step.text);
      this.addStepData(newStep, step);
      scenario.addStep(newStep);
    });

    this.feature.addScenario(scenario);
    return this;
  }

  /**
   * Adds a scenario outline (template) with examples table for data-driven testing.
   * 
   * @param {string} name - The name of the scenario outline
   * @param {StepDefinition[]} steps - Array of step definitions containing placeholders
   * @param {string[][]} examples - 2D array representing the examples table (first row is headers)
   * @param {string[]} [tags] - Optional array of tags for the scenario outline
   * @returns {GherkinFeatureBuilder} The builder instance for method chaining
   * 
   * @example
   * ```typescript
* builder.addScenarioOutline(&#x27;Adding different quantities&#x27;, [
*   { keyword: &#x27;When&#x27;, text: &#x27;the user adds &lt;quantity&gt; of item &quot;&lt;item&gt;&quot;&#x27; },
*   { keyword: &#x27;Then&#x27;, text: &#x27;the cart total should be $&lt;total&gt;&#x27; }
* ], [
*   [&#x27;quantity&#x27;, &#x27;item&#x27;, &#x27;total&#x27;],
*   [&#x27;1&#x27;, &#x27;T-shirt&#x27;, &#x27;25.00&#x27;],
*   [&#x27;2&#x27;, &#x27;Socks&#x27;, &#x27;15.98&#x27;]
* ]);
* ```
   */
  addScenarioOutline(name: string, steps: StepDefinition[], examples: string[][], tags?: string[]): GherkinFeatureBuilder {
    const scenarioOutline = new ScenarioTemplate(name);

    if (tags) {
      tags.forEach(tag => {
        scenarioOutline.addTag(new Tag(tag));
      });
    }

    steps.forEach(step => {
      const newStep = new Step(step.keyword, step.text);
      this.addStepData(newStep, step);
      scenarioOutline.addStep(newStep);
    });

    if (examples && examples.length > 0) {
      const examplesObj = new Examples().withDataTable(new DataTable(examples));
      scenarioOutline.addExamples(examplesObj);
    }

    this.feature.addScenarioTemplate(scenarioOutline);
    return this;
  }

  /**
   * Creates a rule that groups related scenarios.
   * 
   * @param {string} name - The name of the rule
   * @param {string} [description] - Optional description of the rule
   * @returns {RuleBuilder} A rule builder for adding scenarios to this rule
   * 
   * @example
   * ```typescript
* builder
*   .addRule(&#x27;Cart Management&#x27;)
*     .addScenario(&#x27;Adding items&#x27;, addingSteps)
*     .addScenario(&#x27;Removing items&#x27;, removingSteps)
*     .done() // Return to parent builder
* ```
   */
  addRule(name: string, description?: string): RuleBuilder {
    return new RuleBuilder(this, name, description);
  }

  /**
   * Adds a comment to the feature.
   * 
   * @param {string} text - The comment text
   * @returns {GherkinFeatureBuilder} The builder instance for method chaining
   */
  addComment(text: string): GherkinFeatureBuilder {
    this.feature.addComment(new Comment(text));
    return this;
  }

  /**
   * Helper method for adding data to steps
   */
  private addStepData(step: Step, definition: StepDefinition): void {
    if (definition.dataTable) {
      step.withDataTable(new DataTable(definition.dataTable));
    }

    if (definition.docString) {
      step.withDocString(new DocString(definition.docString));
    }
  }

  /**
   * Returns the built Feature object.
   * 
   * @returns {Feature} The constructed Feature object
   */
  build(): Feature {
    return this.feature;
  }

  /**
   * Returns the Document object containing the feature.
   * 
   * @returns {Document} The constructed Document object
   */
  buildDocument(): Document {
    return this.document;
  }

  /**
   * Writes the feature to a file at the specified path.
   * 
   * @param {string} filePath - The path where the feature file should be written
   */
  writeToFile(filePath: string): void {
    writeFeature(this.feature, filePath);
  }
}
```

#### example
```typescript
// Example of creating the Generic Type System feature
export function createGenericTypeSystemFeature(): Feature {
  return new GherkinFeatureBuilder('Generic Type System')
    .addBackground([
      {
        keyword: 'Given',
        text: 'the following generic type parameters are defined:',
        dataTable: [
          ['Parameter', 'Constraint', 'Description'],
          ['T', 'any', 'Primary data type'],
          ['K', 'keyof T', 'Keys of type T'],
          ['E', 'Error', 'Error type extending Error class'],
          ['R', 'T extends S ? X : Y', 'Conditional type based on T']
        ]
      }
    ])
    .addScenarioTemplate(
      'Generic Collection Operations <operation>',
      [
        { keyword: 'Given', text: 'I have a collection of type "Array<T>"' },
        { keyword: 'When', text: 'I perform the "<operation>" operation' },
        { keyword: 'Then', text: 'I should receive a result of type "<resultType>"' }
      ],
      [
        ['operation', 'resultType', 'description'],
        ['map', 'Array<U>', 'Transform each item to type U'],
        ['filter', 'Array<T>', 'Subset of original collection'],
        ['reduce', 'U', 'Aggregated value of type U'],
        ['find', 'T?', 'Optional item of type T']
      ]
    )
    .addScenario(
      'Using Generic Type with Constraints',
      [
        { keyword: 'Given', text: 'I have a generic function with signature "function extract<T, K extends keyof T>(obj: T, key: K)"' },
        { keyword: 'When', text: 'I call the function with an object of type T and a key of type K' },
        { keyword: 'Then', text: 'I should receive a return value of type "T[K]"' }
      ]
    )
    .build();
}
```

#### test
Now, let's create the Jest test file:

```typescript
// gherkin-feature.test.ts
import { Feature, Background, Scenario, ScenarioTemplate } from 'gherkin-ast';
import { GherkinFeatureBuilder, createGenericTypeSystemFeature } from './gherkin-feature';
import * as fs from 'fs';
import * as path from 'path';

// Mock gherkin-io
jest.mock('gherkin-io', () => ({
  writeFeature: jest.fn()
}));

describe('GherkinFeatureBuilder', () => {
  it('should create a feature with a name', () => {
    const builder = new GherkinFeatureBuilder('Test Feature');
    const feature = builder.build();
    
    expect(feature).toBeInstanceOf(Feature);
    expect(feature.name).toBe('Test Feature');
  });

  it('should add a background to a feature', () => {
    const builder = new GherkinFeatureBuilder('Test Feature');
    const feature = builder
      .addBackground([
        { keyword: 'Given', text: 'a test step' }
      ])
      .build();
    
    expect(feature.background).toBeInstanceOf(Background);
    expect(feature.background?.steps.length).toBe(1);
    expect(feature.background?.steps[0].keyword).toBe('Given');
    expect(feature.background?.steps[0].text).toBe('a test step');
  });

  it('should add a scenario to a feature', () => {
    const builder = new GherkinFeatureBuilder('Test Feature');
    const feature = builder
      .addScenario('Test Scenario', [
        { keyword: 'Given', text: 'a test step' }
      ])
      .build();
    
    expect(feature.scenarios.length).toBe(1);
    expect(feature.scenarios[0]).toBeInstanceOf(Scenario);
    expect(feature.scenarios[0].name).toBe('Test Scenario');
    expect(feature.scenarios[0].steps.length).toBe(1);
    expect(feature.scenarios[0].steps[0].keyword).toBe('Given');
    expect(feature.scenarios[0].steps[0].text).toBe('a test step');
  });

  it('should add a scenario template with examples to a feature', () => {
    const builder = new GherkinFeatureBuilder('Test Feature');
    const feature = builder
      .addScenarioTemplate('Test Template <param>', [
        { keyword: 'Given', text: 'a test step with <param>' }
      ], [
        ['param', 'result'],
        ['value1', 'result1'],
        ['value2', 'result2']
      ])
      .build();
    
    expect(feature.scenarioTemplates.length).toBe(1);
    expect(feature.scenarioTemplates[0]).toBeInstanceOf(ScenarioTemplate);
    expect(feature.scenarioTemplates[0].name).toBe('Test Template <param>');
    expect(feature.scenarioTemplates[0].steps.length).toBe(1);
    expect(feature.scenarioTemplates[0].steps[0].keyword).toBe('Given');
    expect(feature.scenarioTemplates[0].steps[0].text).toBe('a test step with <param>');
    expect(feature.scenarioTemplates[0].examples.length).toBe(1);
    expect(feature.scenarioTemplates[0].examples[0].dataTable.rows.length).toBe(3);
  });

  it('should add a data table to a step', () => {
    const builder = new GherkinFeatureBuilder('Test Feature');
    const feature = builder
      .addScenario('Test Scenario', [
        { 
          keyword: 'Given', 
          text: 'a step with a data table',
          dataTable: [
            ['header1', 'header2'],
            ['value1', 'value2']
          ]
        }
      ])
      .build();
    
    const step = feature.scenarios[0].steps[0];
    expect(step.dataTable).toBeDefined();
    expect(step.dataTable?.rows.length).toBe(2);
    expect(step.dataTable?.rows[0][0]).toBe('header1');
    expect(step.dataTable?.rows[1][1]).toBe('value2');
  });

  it('should create the Generic Type System feature correctly', () => {
    const feature = createGenericTypeSystemFeature();
    
    expect(feature.name).toBe('Generic Type System');
    expect(feature.background).toBeDefined();
    expect(feature.scenarioTemplates.length).toBe(1);
    expect(feature.scenarios.length).toBe(1);
    
    // Check background
    expect(feature.background?.steps.length).toBe(1);
    expect(feature.background?.steps[0].dataTable?.rows.length).toBe(5); // Header + 4 rows
    
    // Check scenario template
    expect(feature.scenarioTemplates[0].name).toBe('Generic Collection Operations <operation>');
    expect(feature.scenarioTemplates[0].steps.length).toBe(3);
    expect(feature.scenarioTemplates[0].examples[0].dataTable.rows.length).toBe(5); // Header + 4 rows
    
    // Check scenario
    expect(feature.scenarios[0].name).toBe('Using Generic Type with Constraints');
    expect(feature.scenarios[0].steps.length).toBe(3);
  });

  it('should call writeFeature when writeToFile is called', () => {
    const { writeFeature } = require('gherkin-io');
    const builder = new GherkinFeatureBuilder('Test Feature');
    const filePath = 'test.feature';
    
    builder.writeToFile(filePath);
    
    expect(writeFeature).toHaveBeenCalledWith(expect.any(Feature), filePath);
  });
});
```

This implementation provides:

1. **A flexible ```GherkinFeatureBuilder``` class** that follows the builder pattern you requested, allowing chaining of methods like ```new Feature(name).addBackground().addScenario()```

2. **A ```StepDefinition``` interface** to define steps with keywords, text, and optional data tables

3. **A utility function ```createGenericTypeSystemFeature()```** that demonstrates how to create the specific feature from your example

4. **Comprehensive Jest tests** that verify:
    - Basic feature creation
    - Adding backgrounds, scenarios, and scenario templates
    - Adding data tables to steps
    - Creating the specific Generic Type System feature
    - File writing functionality

The implementation adheres to TypeScript best practices with proper typing, interfaces, and a clean builder pattern design.



## docs?

#### GherkinFeatureBuilder Usage Example

Here's a clear example of how to use the ```GherkinFeatureBuilder``` class to programmatically create the provided Gherkin feature:

```typescript
import { GherkinFeatureBuilder } from './gherkin-feature';

// Create a new instance of the builder with the feature name
const builder = new GherkinFeatureBuilder(
  'Paginated Response Structure',
  'As a developer\nI want to work with paginated data responses\nSo that I can efficiently handle large datasets'
);

// Add the Background section
builder.addBackground([
  {
    keyword: 'Given',
    text: 'a generic type T exists for the response items'
  }
]);

// Add the first Scenario with a DataTable
builder.addScenario(
  'Retrieving a paginated response',
  [
    {
      keyword: 'When',
      text: 'I request a paginated collection of type T'
    },
    {
      keyword: 'Then',
      text: 'I should receive a response with the following structure:',
      dataTable: [
        ['Field', 'Type', 'Description'],
        ['items', 'Array<T>', 'Collection of items of type T'],
        ['total', 'Number', 'Total count of all available items'],
        ['page', 'Number', 'Current page number'],
        ['pageSize', 'Number', 'Number of items per page'],
        ['hasMore', 'Boolean', 'Flag indicating if more pages are available']
      ]
    }
  ]
);

// Add the Scenario Outline with Examples
builder.addScenarioOutline(
  'Validating pagination properties',
  [
    {
      keyword: 'Given',
      text: 'a paginated response of type T'
    },
    {
      keyword: 'When',
      text: 'I check the "<property>" property'
    },
    {
      keyword: 'Then',
      text: 'it should be of type "<type>"'
    }
  ],
  [
    ['property', 'type'],
    ['items', 'Array'],
    ['total', 'Number'],
    ['page', 'Number'],
    ['pageSize', 'Number'],
    ['hasMore', 'Boolean']
  ]
);

// Build the feature and write it to a file
const feature = builder.build();
builder.writeToFile('paginated-response.feature');

// Alternatively, you can use the feature object directly in your code
console.log(feature.name); // "Paginated Response Structure"
```

## Documentation Example

```markdown
# GherkinFeatureBuilder

The `GherkinFeatureBuilder` class provides a fluent API for programmatically creating Gherkin feature files.

## Example Usage

The following example demonstrates how to create a feature file for a paginated response structure:

```typescript
import { GherkinFeatureBuilder } from './gherkin-feature';

// Create a new feature
const builder = new GherkinFeatureBuilder(
  'Paginated Response Structure',
  'As a developer\nI want to work with paginated data responses\nSo that I can efficiently handle large datasets'
);

// Add background steps
builder.addBackground([
  {
    keyword: 'Given',
    text: 'a generic type T exists for the response items'
  }
]);

// Add a scenario with a data table
builder.addScenario(
  'Retrieving a paginated response',
  [
    {
      keyword: 'When',
      text: 'I request a paginated collection of type T'
    },
    {
      keyword: 'Then',
      text: 'I should receive a response with the following structure:',
      dataTable: [
        ['Field', 'Type', 'Description'],
        ['items', 'Array<T>', 'Collection of items of type T'],
        ['total', 'Number', 'Total count of all available items'],
        ['page', 'Number', 'Current page number'],
        ['pageSize', 'Number', 'Number of items per page'],
        ['hasMore', 'Boolean', 'Flag indicating if more pages are available']
      ]
    }
  ]
);

// Add a scenario outline with examples
builder.addScenarioOutline(
  'Validating pagination properties',
  [
    {
      keyword: 'Given',
      text: 'a paginated response of type T'
    },
    {
      keyword: 'When',
      text: 'I check the "<property>" property'
    },
    {
      keyword: 'Then',
      text: 'it should be of type "<type>"'
    }
  ],
  [
    ['property', 'type'],
    ['items', 'Array'],
    ['total', 'Number'],
    ['page', 'Number'],
    ['pageSize', 'Number'],
    ['hasMore', 'Boolean']
  ]
);

// Generate the feature file
builder.writeToFile('paginated-response.feature');
```

This will generate a feature file identical to the one shown below:

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


