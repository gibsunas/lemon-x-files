import {
  formatFiles,
  generateFiles,
  Tree,
  readNxJson,
  updateNxJson,
} from '@nx/devkit';
import * as path from 'path';
import { GithubGeneratorSchema } from './schema';

export async function githubGenerator(
    tree: Tree,
    options: GithubGeneratorSchema
) {
<<<<<<< Updated upstream
  const config = await readNxJson(tree) || {};
  config.release = config.release ?? {}
  config.release.projects = ["packages/*"];
=======
  const config = await readNxJson() ?? undefined;
  if (config) {
    config.release = config.release ?? {}
    config.release.projects = ["packages/*"];

    await updateNxJson(tree, config);
  }
>>>>>>> Stashed changes

  await generateFiles(tree, path.join(__dirname, 'files'), '', options);
  await formatFiles(tree);
}

export default githubGenerator;
