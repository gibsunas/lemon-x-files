import {
  formatFiles,
  Tree,
} from '@nx/devkit';
import { NxPluginBuilder, PrismaPluginOptions, PackageDependencyManager } from '@lemon/x-utils';
import { InitGeneratorSchema } from './schema';

export async function initGenerator(tree: Tree, options: InitGeneratorSchema) {
  const { directory } = options;

  const prismaPlugin = new NxPluginBuilder<PrismaPluginOptions>(tree, '@lemon/x-prisma')
      .withOption('schema', directory ? `${directory}/prisma/schema.prisma` : './prisma/schema.prisma')
      .withOption('outputPath', directory ? `${directory}/src/generated` : './src/generated');

  await prismaPlugin.install();

  await new PackageDependencyManager(tree)
    .withPackageJsonPath(`package.json`)
    .addDevDependency('prisma-generator-typescript-interfaces', '*')
    .addDevDependency('prisma', '*')
    .addDevDependency('@prisma/client', '*')
    .installAndFormat();
  await new PackageDependencyManager(tree)
      .withPackageJsonPath(`${directory}/package.json`)
      .addDevDependency('prisma-generator-typescript-interfaces', '*')
      .addDevDependency('prisma', '*')
      .addDevDependency('@prisma/client', '*')
      .installAndFormat();

  await formatFiles(tree);
}

export default initGenerator;
