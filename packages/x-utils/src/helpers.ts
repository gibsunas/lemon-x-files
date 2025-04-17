import {
  updateNxJson,
  readNxJson,
  installPackagesTask,
  formatFiles,
  addDependenciesToPackageJson,
} from '@nx/devkit';



interface PluginOptions {
  // Define your options interface here
  [key: string]: any;
}

export interface PrismaPluginOptions extends PluginOptions{
  schema?: string;
  outputPath?: string;
  // Add other options as needed
}


export interface UtilsPluginOptions extends PluginOptions{

}
/**
 * Usage example:
 * Define your options
 * ```
 * interface PrismaPluginOptions {
 *   schema?: string;
 *   outputPath?: string;
 *   // Add other options as needed
 * }
 *```
 *
 * Create and use the builder
 * ```
 * const prismaPlugin = new NxPluginBuilder<PrismaPluginOptions>(tree, '@lemon/x-prisma')
 *   .withOption('schema', './prisma/schema.prisma')
 *   .withOption('outputPath', './generated')
 *   // Or use withOptions for multiple options at once
 *   // .withOptions({ schema: './prisma/schema.prisma', outputPath: './generated' })
 *   .install();
 *```
 */
export class NxPluginBuilder<T extends PluginOptions> {
  private nxJson: any;
  private tree: any;
  private pluginName: string;
  private options: Partial<T> = {} as Partial<T>;

  constructor(tree: any, pluginName: string) {
    this.tree = tree;
    this.pluginName = pluginName;
    this.nxJson = readNxJson(tree) || {};
  }

  /**
   * Checks if the plugin is already installed
   */
  hasPlugin(): boolean {
    return this.nxJson.plugins?.some((p: any) =>
        typeof p === 'string'
            ? p === this.pluginName
            : p.plugin === this.pluginName
    ) || false;
  }

  /**
   * Sets an option with type safety
   */
  withOption<K extends keyof T>(key: K, value: T[K]): NxPluginBuilder<T> {
    this.options[key] = value;
    return this;
  }

  /**
   * Sets multiple options at once with type safety
   */
  withOptions(options: Partial<T>): NxPluginBuilder<T> {
    this.options = { ...this.options, ...options };
    return this;
  }

  /**
   * Installs the plugin if not already installed
   */
  install(): void {
    if (!this.hasPlugin()) {
      if (!this.nxJson.plugins) {
        this.nxJson.plugins = [];
      }

      this.nxJson.plugins = [
        ...this.nxJson.plugins,
        {
          plugin: this.pluginName,
          options: this.options,
        },
      ];

      updateNxJson(this.tree, this.nxJson);
      // TODO: this probably should update a package json
    }
  }
}
/**
 * Manages package dependencies for a TypeScript project with a fluent interface.
 * Provides methods to add, install, and manage both production and development dependencies.
 *
 * Example usage:
 *
 * ```typescript
 *     const manager = new PackageDependencyManager(tree);
 *
 *     await manager
 *       .addDependency('react', '^18.0.0')
 *       .addDependencies({ 'react-dom': '^18.0.0', 'react-router': '^6.0.0' })
 *       .addDevDependency('typescript', '^4.5.0')
 *       .addDevDependencies({ 'jest': '^27.0.0', '@types/react': '^18.0.0' })
 *       .installAndFormat();
 * ```
 */
export class PackageDependencyManager {
  /**
   * File tree structure used internally for package operations
   * @private
   */
  private tree: any;

  /**
   * Record of production dependencies (package names and versions)
   * @private
   */
  private dependencies: Record<string, string> = {};

  /**
   * Record of development dependencies (package names and versions)
   * @private
   */
  private devDependencies: Record<string, string> = {};

  /**
   * Path to the package.json file
   * @private
   */
  private packageJsonPath: string = 'package.json';

  /**
   * Creates a new instance of PackageDependencyManager
   * @param {any} tree - The file tree structure to use for package operations
   */
  constructor(tree: any) {
    this.tree = tree;
  }

  /**
   * Adds a single production dependency
   * @param {string} name - The package name
   * @param {string} version - The package version
   * @returns {PackageDependencyManager} The current instance for chaining
   */
  addDependency(name: string, version: string): PackageDependencyManager {
    this.dependencies[name] = version;
    return this;
  }

  /**
   * Adds multiple production dependencies at once
   * @param {Record<string, string>} deps - Record of package names and versions
   * @returns {PackageDependencyManager} The current instance for chaining
   */
  addDependencies(deps: Record<string, string>): PackageDependencyManager {
    this.dependencies = { ...this.dependencies, ...deps };
    return this;
  }

  /**
   * Adds a single development dependency
   * @param {string} name - The package name
   * @param {string} version - The package version
   * @returns {PackageDependencyManager} The current instance for chaining
   */
  addDevDependency(name: string, version: string): PackageDependencyManager {
    this.devDependencies[name] = version;
    return this;
  }

  /**
   * Adds multiple development dependencies at once
   * @param {Record<string, string>} deps - Record of package names and versions
   * @returns {PackageDependencyManager} The current instance for chaining
   */
  addDevDependencies(deps: Record<string, string>): PackageDependencyManager {
    this.devDependencies = { ...this.devDependencies, ...deps };
    return this;
  }

  /**
   * Sets a custom path for package.json
   * @param {string} path - The path to the package.json file
   * @returns {PackageDependencyManager} The current instance for chaining
   */
  withPackageJsonPath(path: string): PackageDependencyManager {
    this.packageJsonPath = path;
    return this;
  }

  /**
   * Updates package.json with the specified dependencies
   * @returns {Promise<void>} A promise that resolves when the update is complete
   */
  async updatePackageJson(): Promise<void> {
    await addDependenciesToPackageJson(
        this.tree,
        this.dependencies,
        this.devDependencies,
        this.packageJsonPath
    );
  }

  /**
   * Updates package.json, installs dependencies, and formats files
   * @returns {Promise<void>} A promise that resolves when all operations are complete
   */
  async installAndFormat(): Promise<void> {
    await this.updatePackageJson();
    await installPackagesTask(this.tree);
    await formatFiles(this.tree);
  }

  /**
   * Clears all dependencies that have been added
   * @returns {PackageDependencyManager} The current instance for chaining
   */
  clear(): PackageDependencyManager {
    this.dependencies = {};
    this.devDependencies = {};
    return this;
  }
}

