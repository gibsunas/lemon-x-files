import { createTreeWithEmptyWorkspace } from '@nx/devkit/testing';
import { Tree, readProjectConfiguration } from '@nx/devkit';

import { graphqlGenerator } from './graphql';
import { GraphqlGeneratorSchema } from './schema';

describe('graphql generator', () => {
  let tree: Tree;
  const options: GraphqlGeneratorSchema = { directory: '' };

  beforeEach(() => {
    tree = createTreeWithEmptyWorkspace();
  });

  it('should run successfully', async () => {
    await graphqlGenerator(tree, options);
  });
});
