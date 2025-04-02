import {
  addProjectConfiguration,
  formatFiles,
  generateFiles,
  Tree,
} from '@nx/devkit';
import * as path from 'path';
import { EditorGeneratorSchema } from './schema';

export async function editorConfigGenerator(
    tree: Tree,
    options: EditorGeneratorSchema
) {

  generateFiles(tree, path.join(__dirname, 'files'), '', options);
  await formatFiles(tree);
}

export default editorConfigGenerator;
