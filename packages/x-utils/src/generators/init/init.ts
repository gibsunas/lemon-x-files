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
<<<<<<< Updated upstream



  // Begin bad practice 
  // Dev dependencies in the root package.json
  await new PackageDependencyManager(tree)
    .withPackageJsonPath(`package.json`)
    .addDevDependency('@angular-devkit/core', '^19.2.11')
    .addDevDependency('@babel/core', '^7.14.5')
    .addDevDependency('@babel/preset-react', '^7.14.5')
    .addDevDependency('@eslint/js', '^9.8.0')
    .addDevDependency('@melloware/react-logviewer', '*')
    .addDevDependency('@nestjs/schematics', '^10.0.1')
    .addDevDependency('@nestjs/testing', '^10.0.2')
    .addDevDependency('@nx/cypress', '21.0.2')
    .addDevDependency('@nx/eslint', '21.0.2')
    .addDevDependency('@nx/eslint-plugin', '21.0.2')
    .addDevDependency('@nx/express', '^21.0.2')
    .addDevDependency('@nx/jest', '21.0.2')
    .addDevDependency('@nx/js', '^21.0.2')
    .addDevDependency('@nx/nest', '^21.0.2')
    .addDevDependency('@nx/node', '21.0.2')
    .addDevDependency('@nx/plugin', '^21.0.2')
    .addDevDependency('@nx/react', '^21.0.2')
    .addDevDependency('@nx/web', '21.0.2')
    .addDevDependency('@nx/webpack', '^21.0.2')
    .addDevDependency('@pmmmwh/react-refresh-webpack-plugin', '^0.5.7')
    .addDevDependency('@prisma/client', '*')
    .addDevDependency('@radix-ui/themes', '*')
    .addDevDependency('@svgr/webpack', '^8.0.1')
    .addDevDependency('@swc-node/register', '~1.9.1')
    .addDevDependency('@swc/cli', '~0.6.0')
    .addDevDependency('@swc/core', '~1.5.7')
    .addDevDependency('@swc/helpers', '~0.5.11')
    .addDevDependency('@swc/jest', '~0.2.36')
    .addDevDependency('@testing-library/dom', '10.4.0')
    .addDevDependency('@testing-library/react', '16.1.0')
    .addDevDependency('@types/express', '^4.17.21')
    .addDevDependency('@types/jest', '^29.5.12')
    .addDevDependency('@types/node', '^20.0.0')
    .addDevDependency('@types/react', '19.0.0')
    .addDevDependency('@types/react-dom', '19.0.0')
    .addDevDependency('babel-jest', '^29.7.0')
    .addDevDependency('cypress', '^14.2.1')
    .addDevDependency('eslint', '^9.8.0')
    .addDevDependency('eslint-config-prettier', '^10.0.0')
    .addDevDependency('eslint-plugin-cypress', '^3.5.0')
    .addDevDependency('eslint-plugin-import', '2.31.0')
    .addDevDependency('eslint-plugin-jsx-a11y', '6.10.1')
    .addDevDependency('eslint-plugin-react', '7.35.0')
    .addDevDependency('eslint-plugin-react-hooks', '5.0.0')
    .addDevDependency('gherkin-io', '^1.3.0')
    .addDevDependency('jest', '^29.7.0')
    .addDevDependency('jest-environment-jsdom', '^29.7.0')
    .addDevDependency('jest-environment-node', '^29.7.0')
    .addDevDependency('jsonc-eslint-parser', '^2.1.0')
    .addDevDependency('nx', '21.0.2')
    .addDevDependency('prettier', '^2.6.2')
    .addDevDependency('prisma', '*')
    .addDevDependency('prisma-generator-typescript-interfaces', '*')
    .addDevDependency('react-refresh', '^0.10.0')
    .addDevDependency('ts-jest', '^29.1.0')
    .addDevDependency('ts-node', '10.9.1')
    .addDevDependency('tslib', '^2.3.0')
    .addDevDependency('typescript', '~5.7.2')
    .addDevDependency('typescript-eslint', '^8.19.0')
    .addDevDependency('webpack-cli', '^5.1.4')
    .installAndFormat();
  
  // Regular dependencies in the child package.json
  await new PackageDependencyManager(tree)
    .withPackageJsonPath(`${directory}/package.json`)
    .addDependency('@lemon/create-ade-stand', '^0.0.4-69')
    .addDependency('@nestjs/common', '^10.0.2')
    .addDependency('@nestjs/core', '^10.0.2')
    .addDependency('@nestjs/mapped-types', '*')
    .addDependency('@nestjs/platform-express', '^10.0.2')
    .addDependency('@nx/devkit', '21.0.2')
    .addDependency('axios', '^1.6.0')
    .addDependency('express', '^4.21.2')
    .addDependency('react', '19.0.0')
    .addDependency('react-dom', '19.0.0')
    .addDependency('react-router-dom', '6.29.0')
    .addDependency('reflect-metadata', '^0.1.13')
    .addDependency('rxjs', '^7.8.0')
    .installAndFormat();

  // End this bad practice
=======
>>>>>>> Stashed changes
}

export default initGenerator;
