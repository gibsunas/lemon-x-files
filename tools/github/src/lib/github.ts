import {
  addProjectConfiguration,
  formatFiles,
  generateFiles,
  Tree,
} from '@nx/devkit';
import * as path from 'path';
import { GithubGeneratorSchema } from './schema';

export async function githubGenerator(
    tree: Tree,
    options: GithubGeneratorSchema
) {

  generateFiles(tree, path.join(__dirname, 'files'), '', options);
  await formatFiles(tree);
}

export default githubGenerator;
