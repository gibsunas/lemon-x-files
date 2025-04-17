// Based on https://nx.dev/extending-nx/recipes/project-graph-plugins
import { createNodesFromFiles, CreateNodesContextV2, CreateNodesV2 } from '@nx/devkit';
import { dirname, join } from 'path';

export interface PrismaPluginOptions {}

export const createNodesV2 = [
  '**/schema.prisma',
  async (configFiles: string[], options:PrismaPluginOptions = {}, context:CreateNodesContextV2) => {
    return await createNodesFromFiles(
      (configFile, options, context) =>
        createNodesInternal(configFile, options, context),
      configFiles,
      options,
      context
    );
  },
];

async function createNodesInternal(
  configFilePath: string,
  options: PrismaPluginOptions = {},
  context: CreateNodesContextV2
) {

  const root = dirname(join(configFilePath, '..'));

  return {
    projects: {
      [root]: {
          targets: {
              prisma: {
                "executor": "nx:run-commands",
                "options": {
                  "cwd": root,
                  "commands": [
                    `prisma generate --no-hints`
                  ],
                  "parallel": false
                }
              },

          }
      },
    },
  };
}