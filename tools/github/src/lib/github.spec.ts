import { createTreeWithEmptyWorkspace } from '@nx/devkit/testing';
import { Tree, readProjectConfiguration } from '@nx/devkit';

import { githubGenerator } from './github';
import { GithubGeneratorSchema } from './schema';

describe('github generator', () => {
  let tree: Tree;
  const options: GithubGeneratorSchema = { name: 'test' };

  beforeEach(() => {
    tree = createTreeWithEmptyWorkspace();
  });

  it('should run successfully', async () => {
    await githubGenerator(tree, options);
  });
});
