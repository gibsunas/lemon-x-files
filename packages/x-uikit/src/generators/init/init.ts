import {
  formatFiles,
  Tree,
  updateNxJson,
  readNxJson,
  addDependenciesToPackageJson,
} from '@nx/devkit';
import { InitGeneratorSchema } from './schema';

export async function initGenerator(tree: Tree, options: InitGeneratorSchema) {
  const directory = options.directory
  const nxJson = readNxJson(tree) || {};
  const hasPlugin = nxJson
      .plugins?.some((p) => typeof p === 'string'
          ? p === '@lemon/x-uikit'
          : p.plugin === '@lemon/x-uikit'
      );
  if (!hasPlugin) {
    if (!nxJson.plugins) {
      nxJson.plugins = [];
    }
    nxJson.plugins = [
      ...nxJson.plugins,
      {
        plugin: '@lemon/x-uikit',
        options: {},
      },
    ];

  }
  updateNxJson(tree, nxJson);
  const go = addDependenciesToPackageJson(tree, {  }, {'@radix-ui/themes': '*' }, directory ? `${directory}/package.json`: `package.json`);
  await go();
  await formatFiles(tree);
}

export default initGenerator;
