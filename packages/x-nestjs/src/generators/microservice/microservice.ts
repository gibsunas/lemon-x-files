import {
  addDependenciesToPackageJson,
  formatFiles,
  installPackagesTask,
  Tree
} from '@nx/devkit';
import { PackageDependencyManager } from '@lemon/x-utils';
import { MicroserviceGeneratorSchema } from './schema';

export async function microserviceGenerator(
  tree: Tree,
  options: MicroserviceGeneratorSchema
) {
  const { directory } = options;

  await new PackageDependencyManager(tree)
      .withPackageJsonPath(directory ? `${directory}/package.json`: `package.json`)
      .addDevDependency('@nestjs/microservices', '*')
      .addDevDependency('@nestjs/websockets', '*')
      .installAndFormat();

  await formatFiles(tree);
}

export default microserviceGenerator;
