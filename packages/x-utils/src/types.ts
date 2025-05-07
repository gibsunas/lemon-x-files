import { randomUUID as v4, UUID } from "node:crypto";

/**
 *  UniqueObject
 *
 *  A transient object used once
 *  or lives for the equivalent of
 *  a single transaction
 *
 *  If you find yourself using
 *  these and need them indexed
 *  convert them to PermanentObjects
 *  first
 */
export class UniqueObject {
  public readonly _id: UUID;

  constructor() {
    this._id = v4();
  }
}

/**
 *  PermanentObject
 *
 *  Used for objects that are referred to multiple times
 *  or cross multiple transactions. Anything indexed in a database
 *  should return this interface
 *
 */
export class PermanentObject {
  public readonly id: UUID;

  constructor(x:UniqueObject | undefined) {
    this.id = x?._id ?? v4();
  }
}


export default {
  PermanentObject,
  UniqueObject,
}