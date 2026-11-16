@solaredge
@isotope
@failure-class-store
@z0-physical
@domain-utility-data
Feature: Isotope — solaredge/store

  The local boundary. It never reaches the network, so it should succeed even
  when every upstream isotope has refused. Its job is to keep what was already
  collected and to refuse visibly rather than corrupt.

  Background:
    Given the database is a SQLite file supplied on the command line

  Rule: writes are idempotent

    Scenario: re-fetching a window does not duplicate rows
      Given rows for 2026-11-13 exist
      When the host syncs the same window again
      Then the row count is unchanged
      And the maximum observed_at is unchanged

    Scenario: a partial run keeps earlier rows
      Given a sync writes 15-minute rows and then fails on hourly rows
      Then the 15-minute rows are committed
      And the hourly rows are not partially written

  Rule: drift is refused, not guessed

    Scenario: a newer schema refuses the write
      Given the database schema version is newer than the host expects
      Then the failure class is "store/schema-drift"
      And the run exits non-zero without writing
      And no table is dropped

  Rule: contention is retried, not lost

    Scenario: a locked database is retried with backoff
      Given another process holds a write lock
      When the host writes
      Then the host retries with backoff
      And on exhaustion the failure class is "store/locked"

    Scenario: a failed write is a visible failure
      Given the write returns an error
      Then the failure class is "store/write-failed"
      And the run exits non-zero
