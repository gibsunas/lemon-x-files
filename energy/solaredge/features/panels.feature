@solaredge
@isotope
@failure-class-panels
@z0-physical
@domain-utility-data
Feature: Isotope — solaredge/panels

  Per-optimizer daily energy. This is the isotope that makes panel A/B testing
  possible, so identity matters more here than volume: a panel whose optimizer
  mapping silently changes invalidates every comparison made across the change.

  Background:
    Given the topology endpoint is "/services/layout/logical/generic/v2/site/{id}"
    And the panel energy endpoint is "/services/layout/energy/site/{id}/by-inverter"

  Rule: panel identity is pinned

    Scenario: the inverter serial set matches what was stored
      Given the topology reports inverter serials
      And the stored serials match
      Then panel energy is attributed by optimizer serial
      And no failure class is recorded

    Scenario: the inverter serial set has changed
      Given the topology reports inverter serials
      And the stored serials do not match
      Then the failure class is "panels/inverter-changed"
      And panel rows are not written
      And the alarm states that cross-change comparisons are invalid

  Rule: a missing panel is visible

    Scenario: topology returns no optimizers
      Given the topology endpoint returns no optimizers
      Then the failure class is "panels/no-topology"
      And the run is retried on the next interval
      And no panel rows are written

    Scenario: an optimizer has no reading for the date
      Given topology returns optimizers
      And one optimizer has no energy for the requested date
      Then the failure class is "panels/no-data"
      And the other optimizers are still written
      And the missing serial is named in the record

  Rule: the panel isotope never blocks the series isotope

    Scenario: panel collection fails after series collection succeeds
      Given series rows were written successfully
      When panel collection fails
      Then the series rows remain committed
      And the failure is recorded against the panels isotope only
