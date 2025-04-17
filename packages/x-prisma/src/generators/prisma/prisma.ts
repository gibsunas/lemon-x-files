import {
  readProjectConfiguration,
  formatFiles,
  generateFiles,
  Tree,
} from '@nx/devkit';
import * as path from 'path';

import { initGenerator } from '../init/init';
import { PrismaGeneratorSchema } from './schema';

export async function prismaGenerator(
  tree: Tree,
  options: PrismaGeneratorSchema
) {
  const projectRoot = readProjectConfiguration(tree,options.project).root;

  await initGenerator(tree, {directory: projectRoot})
  const formattedOptions = {
    ...options,
    name: options.name.toLowerCase().replace(/[^a-zA-Z0-9]+(.)/g, (m, chr) => chr.toUpperCase())
  }
  generateFiles(tree, path.join(__dirname, 'files'), projectRoot, formattedOptions);
  await formatFiles(tree);
}

export default prismaGenerator;
