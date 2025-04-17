import {
  addProjectConfiguration,
  formatFiles,
  generateFiles,
  Tree,
} from '@nx/devkit';
import * as path from 'path';
import { GherkinGeneratorSchema } from './schema';
import { PackageDependencyManager } from '../../helpers';

export async function gherkinGenerator(
  tree: Tree,
  options: GherkinGeneratorSchema
) {
  const projectRoot = `libs/${options.name}`;
  addProjectConfiguration(tree, options.name, {
    root: projectRoot,
    projectType: 'library',
    sourceRoot: `${projectRoot}/src`,
    targets: {},
  });
  generateFiles(tree, path.join(__dirname, 'files'), projectRoot, options);

  await new PackageDependencyManager(tree)
      .withPackageJsonPath(`package.json`)
      .addDevDependency('gherkin-ios', '*')
      .addDevDependency('@cucumber/messages', '*')
      .installAndFormat();
  await new PackageDependencyManager(tree)
      .withPackageJsonPath(`${projectRoot}/package.json`)
      .addDevDependency('gherkin-io', '*')
      .addDevDependency('@cucumber/messages', '*')
      .installAndFormat();
  // await formatFiles(tree);
}

export default gherkinGenerator;
