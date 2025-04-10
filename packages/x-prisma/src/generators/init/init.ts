import {
  formatFiles,
  Tree,
} from '@nx/devkit';
import { NxPluginBuilder, PrismaPluginOptions, PackageDependencyManager } from '@lemon/x-utils';
import { InitGeneratorSchema } from './schema';

export async function initGenerator(tree: Tree, options: InitGeneratorSchema) {
  const directory = options.directory

  const prismaPlugin = new NxPluginBuilder<PrismaPluginOptions>(tree, '@lemon/x-prisma')
      .withOption('schema', './prisma/schema.prisma')
      .withOption('outputPath', './generated');

  await prismaPlugin.install();

  await new PackageDependencyManager(tree)
      .withPackageJsonPath(directory ? `${directory}/package.json`: `package.json`)
      .addDevDependency('prisma-generator-typescript-interfaces', '*')
      .installAndFormat();

  await formatFiles(tree);
}

export default initGenerator;
