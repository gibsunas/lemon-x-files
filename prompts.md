# Generic Prompts for TypeScript-Gherkin Conversions
## 0. First pass (refined from a conversation with claude3.7)
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
## 1. TypeScript to Gherkin Conversion Prompt

```
Convert the following TypeScript interface/type definition to a Gherkin feature that preserves all structural and type information. Focus on representing the types, constraints, and relationships accurately in Gherkin format.

TypeScript:

// Paste your TypeScript interface/type here

Please provide only the Gherkin representation without additional explanation.
```

## 2. Gherkin to TypeScript Conversion Prompt

```
Convert the following Gherkin feature to TypeScript interface(s)/type(s) that preserve all structural and type information. Infer appropriate TypeScript types from the natural language descriptions and ensure the resulting TypeScript is properly documented.

Gherkin:
`gherkin
# Paste your Gherkin feature here
`

Please provide only the TypeScript representation without additional explanation.
```

## 3. Conversion Analysis Prompt

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

