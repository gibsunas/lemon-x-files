import {
  readProjectConfiguration,
  formatFiles,
  generateFiles,
  Tree,
} from '@nx/devkit';
import * as path from 'path';

import { initGenerator } from '../init/init';
import { PrismaGeneratorSchema } from './schema';

function toPascalCase(name:string) {
  // If name starts with underscore, return it unchanged
  if (name.startsWith('_')) {
    return name;
  }

  // Otherwise convert to Pascal case
  return name.toLowerCase()
      // First replace all non-alphanumeric characters followed by a letter with uppercase letter
      .replace(/[^a-zA-Z0-9]+(.)/g, (m:string, chr:string) => chr.toUpperCase())
      // Then capitalize the first letter
      .replace(/^[a-z]/, (match: string) => match.toUpperCase());
}


export async function prismaGenerator(
  tree: Tree,
  options: PrismaGeneratorSchema
) {
  const projectRoot = readProjectConfiguration(tree,options.project).root;

  await initGenerator(tree, {directory: projectRoot})
  const formattedOptions = {
    ...options,
    name: toPascalCase(options.name)
  }
  generateFiles(tree, path.join(__dirname, 'files'), projectRoot, formattedOptions);
  await formatFiles(tree);
}

export default prismaGenerator;
