import { createTreeWithEmptyWorkspace } from '@nx/devkit/testing';
import { Tree, readProjectConfiguration } from '@nx/devkit';

import { microserviceGenerator } from './microservice';
import { MicroserviceGeneratorSchema } from './schema';

describe('microservice generator', () => {
  let tree: Tree;
  const options: MicroserviceGeneratorSchema = { directory: '' };

  beforeEach(() => {
    tree = createTreeWithEmptyWorkspace();
  });

  it('should run successfully', async () => {
    await microserviceGenerator(tree, options);
  });
});
