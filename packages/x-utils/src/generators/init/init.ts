import {
  Tree,
  generateFiles
} from '@nx/devkit';
import { join } from 'path';
import { InitGeneratorSchema } from './schema';
import { NxPluginBuilder, UtilsPluginOptions, PackageDependencyManager } from '@lemon/x-utils';


export async function initGenerator(tree: Tree, options: InitGeneratorSchema) {
  const { directory, logUrl = '/hookers/sse/ping'} = options;
  await new NxPluginBuilder<UtilsPluginOptions>(tree,'@lemon/x-utils')
    .install();


  const filePath = `${directory}/webpack.config.js`;
  if (filePath && tree.exists(filePath)) {
    const contents = tree?.read(filePath)?.toString() ?? '';
    // switch to next port to prevent replace from rerunning later
    const newContents = contents
        .replace('plugins: [', `
ignoreWarnings: [
  {
    module: /@melloware\\/react-logviewer/,
    message: /Failed to parse source map/,
  },
],
plugins: [`)
        .replace('port: 4200,', `port: 4201,
  proxy: [{
    context: ['/'],
    target: 'http://192.168.1.30:3001',
    pathRewrite: { '^/': '' }},
  ],
`);
    tree?.write(filePath, newContents);
  }
  generateFiles(tree, join(__dirname, 'files'), directory, options);
  await new PackageDependencyManager(tree)
      .withPackageJsonPath(`package.json`)
      .addDevDependency('@melloware/react-logviewer', '*')
      .installAndFormat();
  await new PackageDependencyManager(tree)
      .withPackageJsonPath(`${directory}/package.json`)
      .addDevDependency('@melloware/react-logviewer', '*')
      .installAndFormat();
}

export default initGenerator;
