// Define our core components
export type Subject = 'user' | 'developer' | 'admin' | 'tester';
export type UserRole = 'anonymous' | 'basic_user' | 'developer' | 'admin' | 'security_team';
export type Action = 'examines' | 'requests' | 'attempts to access';
export type Ev = 'examined' | 'requested' | 'accessed' | 'failed to access';
export type Ob = 'schema' | 'documentation' | 'API' | 'database';
export type Condition = `with role ${UserRole}` | 'with valid credentials' | 'without authentication';

// Compose these into step templates
export type GivenStep = `${Subject} ${Condition} ${Action}`;
export type WhenStep = `When the ${Subject} ${'' | ` ${Condition}`} ${Action} ${Ob}`;
export type ThenStep = `Then ${Subject} ${Ev} ${Ob}`;

/**
 * Create a builder that enforces this structure
 */
export class GivenStepBuilder {
  private subject: Subject = 'user';
  private condition: Condition | '' = '';
  private action: Action = 'examines';
  private object: Ob = 'schema';

  withSubject(subject: Subject): GivenStepBuilder {
    this.subject = subject;
    return this;
  }

  withRole(role: UserRole): GivenStepBuilder {
    this.condition = `with role ${role}`;
    return this;
  }

  withAction(action: Action): GivenStepBuilder {
    this.action = action;
    return this;
  }

  withObject(object: Ob): GivenStepBuilder {
    this.object = object;
    return this;
  }

  build(): GivenStep {
    return `${this.subject} ${this.condition} ${this.action} ${this.object}` as GivenStep;
  }
}

// const a = new GivenStepBuilder()
//   .withObject('database')
//   .withAction('requests')
//   .build();

// const b:GivenStep = ''
// More precise template literal types
// type GivenUserStep<R extends UserRole> =
//   `Given a user with role "${R}" wants to examine the schema`;

// type ThenPermissionStep<
//   P extends 'have' | 'not have access to',
//   Perm extends 'schema:read' | 'schema:admin'
// > = `Then they should ${P} the "${Perm}" permission`;

// Function that enforces correct combinations
// function createScenario<
//   R extends UserRole,
//   P extends 'have' | 'not have access to',
//   Perm extends 'schema:read' | 'schema:admin'
// >(role: R, permissionCheck: P, permission: Perm): string {
//   return `
//   Scenario: Schema authorization for ${role}
//     ${`Given a user with role "${role}" wants to examine the schema`}
//     When they request the schema through introspection
//     Then they should have valid authentication credentials
//     And they should ${permissionCheck} the "${permission}" permission
//   `;
// }

// Usage with full type checking
// const scenario = createScenario('admin', 'have', 'schema:admin');

export type TableRow = Record<string, string | number>;



/**
 * Usage
 * ```
 *    new DataTable()
 *     .withHeaders('role', 'permission_requirement', 'required_permission')
 *     .addRow({
 *       role: 'admin',
 *       permission_requirement: 'have',
 *       required_permission: 'schema:admin'
 *     })
 *     .addRow({
 *       role: 'basic_user',
 *       permission_requirement: 'have',
 *       required_permission: 'schema:read'
 *     })
 *     .build();
 *```
 */
export class DataTable {
  private headers: string[] = [];
  private rows: TableRow[] = [];

  withHeaders(...headers: string[]): DataTable {
    this.headers = headers;
    return this;
  }

  addRow(row: TableRow): DataTable {
    // Validate that row has all required headers
    const missingHeaders = this.headers.filter(h => !(h in row));
    if (missingHeaders.length > 0) {
      throw new Error(`Missing required headers: ${missingHeaders.join(', ')}`);
    }

    this.rows.push(row);
    return this;
  }

  build(): string {
    const headerRow = `| ${this.headers.join(' | ')} |`;
    const dataRows = this.rows.map(row =>
      `| ${this.headers.map(h => row[h]).join(' | ')} |`
    );

    return [headerRow, ...dataRows].join('\n');
  }
}


