@cyberpower
@isotope
@failure-class-store
@z0-physical
@domain-energy
Feature: Isotope — cyberpower/store

  The local boundary. It must keep working when the network boundary has
  refused, and it must never turn a failed poll into a plausible row.

  Rule: a poll that did not measure writes no sample

    Scenario: an unreachable unit writes a run and no samples
      Given the unit "spare" is unreachable
      When the collector polls
      Then a run is recorded for "spare" with status "unreachable"
      And no sample is written for "spare"

  Rule: the store is keyed by unit, not by address

    Scenario: re-addressing a unit keeps its history
      Given the unit "rack" has samples recorded at one address
      When the unit "rack" answers at a different address
      Then its history is still under "rack"
      And the device row carries the new address

  Rule: the schema moves forward in place

    Scenario: a v1 store is migrated without losing rows
      Given a store written by the single-unit collector
      When the collector opens it
      Then the schema version is "ups-readings/2"
      And the existing rows are under the unit label "ups"

    Scenario: a newer schema is refused, not downgraded
      Given the store schema is newer than the collector expects
      When the collector opens it
      Then the failure class is "store/schema-drift"
      And the collector exits non-zero without writing
      And the schema marker is unchanged

  Rule: contention is retried, not lost

    Scenario: a second collector cannot interleave
      Given another collector holds the store lock
      When this collector starts
      Then it exits with a message naming the lock
      And no run is recorded

    Scenario: a failed write is a visible failure
      Given the write returns an error
      When the collector writes
      Then the failure class is "store/write-failed"
      And the collector exits non-zero
