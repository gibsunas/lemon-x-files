import {
  addDependenciesToPackageJson,
  formatFiles,
  installPackagesTask,
  Tree,
} from '@nx/devkit';
import { GraphqlGeneratorSchema } from './schema';
import { format } from "gherkin-formatter";
import { Document } from "gherkin-io";
import { Feature, Rule }from "gherkin-ast";
import { PackageDependencyManager } from '@lemon/x-utils';

export async function graphqlGenerator(
    tree: Tree,
    options: GraphqlGeneratorSchema
) {
  const { directory } = options;

  await new PackageDependencyManager(tree)
      .withPackageJsonPath(directory ? `${directory}/package.json`: `package.json`)
      .addDevDependency('@nestjs/graphql', '*')
      .installAndFormat();

  const testDoc = `
# Start comment(s) of the Document

# Before tags comment of the Feature
@tag1 @tag2
# Tag comment of @tag3 Tag
@tag3
# Preceding comment of the Feature
Feature: Name

  This is a multiline
  Feature description

  # Description comment of the Feature

  # Before tags comment of the Rule
  @tag1 @tag2
  # Preceding comment of the Rule
  Rule: Name

    This is a multiline
    Rule description

    # Description comment of the Rule

    # Preceding comment of the Background
    Background: Name

      This is a multiline
      Background description

      # Description comment of the Background

      # Comment of the given step
      Given step
      # Comment of the when step
      When step
      # Comment of the then step
      Then step

    # Before tags comment of the Scenario
    @tag1 @tag2
    # Preceding comment of the Scenario
    Scenario: Name

      This is a multiline
      Scenario description

      # Description comment of the Scenario

      # Comment of the given step
      Given step
        # Comment of the docstirng
        """
        docstring
        other docstring
        """
      # Comment of the when step
      When step
        # Comment of the data table row
        | data  | table |
        # Comment of the data table row
        | value | value |
        # Comment of the data table row
        | value | value |
      # Comment of the then step
      Then step
        """markdown
        title
        =====
        docstring with content type
        """
      And step
        \`\`\`markdown
        docstring with backtick and content type
        \`\`\`

    # Before tags comment of the ScenarioOutline
    @tag1 @tag2
    # Preceding comment of the ScenarioOutline
    Scenario Outline: Name

      This is a multiline
      ScenarioOutline description

      # Description comment of the ScenarioOutline

      Given step <v>
      When step <w>

      # Before tags comment of the Examples
      @tag1 @tag2
      # Preceding comment of the Examples
      Examples: Name
        # Comment of the examples table row
        | v | w |
        # Comment of the examples table row
        | 1 | 2 |
        # Comment of the examples table row
        | 2 | 3 |

# End comment(s) of the Document
`;

  const f = new Feature("Feature","AST Test Feature","I exist, therefore I am", "en");
  const r = new Rule("Rule", "Any objects that can be referenced should have an id", "When someone gets rick-rolled" +
      " we need to know how")
  const r_id = new Rule("Rule", "An id should be unique", "uuidV4")
  r.elements.push(r_id as any);
  // const document: Document = await parse(testDoc as any, '1.feature');
  const _options = { separateStepGroups: false };
  // console.dir(f)
  const t = new Document(`${directory}/features/id.feature`, {
    ...f,
    elements: [ r ] as any
  } as any);
  // console.log(format(document,_options));

  console.dir(t,{ depth: 5})
  tree.write(t.uri,format(t,_options));
  await formatFiles(tree);
}

export default graphqlGenerator;
