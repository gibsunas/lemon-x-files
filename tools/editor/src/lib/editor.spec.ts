import { createTreeWithEmptyWorkspace } from '@nx/devkit/testing';
import { Tree, readProjectConfiguration } from '@nx/devkit';

import { editorConfigGenerator } from './editor';
import { EditorGeneratorSchema } from './schema';

describe('github generator', () => {
  let tree: Tree;
  const options: EditorGeneratorSchema = { name: 'test' };

  beforeEach(() => {
    tree = createTreeWithEmptyWorkspace();
  });

  it('should run successfully', () => {
    editorConfigGenerator(tree, options);
  });
});
