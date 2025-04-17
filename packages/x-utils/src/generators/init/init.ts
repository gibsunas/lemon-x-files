import {
  Tree
} from '@nx/devkit';
import { InitGeneratorSchema } from './schema';
import { NxPluginBuilder, UtilsPluginOptions, PackageDependencyManager } from '@lemon/x-utils';

export async function initGenerator(tree: Tree, options: InitGeneratorSchema) {
  // const { directory, name} = options;
  await new NxPluginBuilder<UtilsPluginOptions>(tree,'@lemon/x-utils')
    .install();

  // await new PackageDependencyManager(tree)
  //     .withPackageJsonPath(`package.json`)
  //     .addDevDependency('gherkin-ios', '*')
  //     .addDevDependency('@cucumber/messages', '*')
  //     .installAndFormat();
  // await new PackageDependencyManager(tree)
  //     .withPackageJsonPath(`${directory}/package.json`)
  //     .addDevDependency('gherkin-io', '*')
  //     .addDevDependency('@cucumber/messages', '*')
  //     .installAndFormat();
}

export default initGenerator;
