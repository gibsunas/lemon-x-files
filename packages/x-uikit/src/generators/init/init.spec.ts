import { createTreeWithEmptyWorkspace } from '@nx/devkit/testing';
import { Tree } from '@nx/devkit';

import { initGenerator } from './init';

describe('init generator', () => {
  let tree: Tree;
  const options = { directory: '' };

  beforeEach(() => {
    tree = createTreeWithEmptyWorkspace();
  });

  it('should run successfully', async () => {
    await initGenerator(tree, options);
  });
});
