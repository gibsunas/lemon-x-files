import {
  formatFiles,
  Tree,
} from '@nx/devkit';
import { NxPluginBuilder, PrismaPluginOptions, PackageDependencyManager } from '@lemon/x-utils';
import { InitGeneratorSchema } from './schema';

export async function initGenerator(tree: Tree, options: InitGeneratorSchema) {
  const directory = options.directory

  const prismaPlugin = new NxPluginBuilder<PrismaPluginOptions>(tree, '@lemon/x-nestjs');

  await prismaPlugin.install();

  await new PackageDependencyManager(tree)
      .withPackageJsonPath(directory ? `${directory}/package.json`: `package.json`)
      .addDevDependency('gherkin-io', '^1.3.0')
      .installAndFormat();

  await formatFiles(tree);
}

export default initGenerator;
