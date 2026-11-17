@cyberpower
@isotope
@failure-class-snmp
@z0-physical
@domain-energy
Feature: Isotope — cyberpower/snmp

  The network boundary: one UDP read of the card's CPS-MIB group per poll. The
  dangerous failure is not an error — it is a reading that looks like a
  measurement but came from the wrong unit or a truncated response.

  Rule: a unit that does not answer is a recorded state, not a crash

    Scenario: an unreachable unit is recorded and the other unit is still polled
      Given two units are configured, "rack" and "spare"
      And "spare" does not answer on UDP 161
      When the collector polls every configured unit once
      Then the "spare" run is recorded with status "unreachable"
      And the "rack" run is recorded with status "ok"
      And the command exits 0

    Scenario: every unit failing is a non-zero run
      Given every configured unit is unreachable
      When the collector polls every configured unit once
      Then every run is recorded with status "unreachable"
      And the command exits 1

  Rule: a scalar the model does not implement is absent, not zero

    Scenario: an absent scalar is not written
      Given the card returns noSuchName for "battery_voltage"
      When the collector polls
      Then no "battery_voltage" sample is written
      And the run is recorded with status "ok"

  Rule: a response that cannot be parsed is never a measurement

    Scenario: a malformed response is an error, not an absent unit
      Given the card returns a response that is not valid BER
      When the collector polls
      Then the run is recorded with status "error"
      And no sample is written for that unit

    Scenario: a device error-status is an error, not an absent unit
      Given the card returns error-status 5
      When the collector polls
      Then the run is recorded with status "error"
      And no sample is written for that unit
