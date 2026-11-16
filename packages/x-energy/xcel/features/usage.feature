@xcel
@isotope
@failure-class-usage
@z0-physical
@domain-utility-data
Feature: Isotope — xcel/usage

  The data boundary. The dangerous failure here is not an error — it is an HTML
  login page parsed as if it were a dataset, which would silently truncate
  history. Empty results and failed results must never look alike.

  Background:
    Given the usage endpoint is "https://myenergy.xcelenergy.com/myenergy/usage-history-ajax/format/json"

  Rule: HTML is never parsed as data

    Scenario: a login redirect is an auth failure, not an empty dataset
      Given the usage endpoint returns HTML
      Then the failure class is "usage/session-expired"
      And no rows are written
      And previously stored rows are not deleted

    Scenario: a non-200 response writes nothing
      Given the usage endpoint returns HTTP 500
      Then the failure class is "usage/malformed-payload"
      And no rows are written

  Rule: empty is not the same as failed

    Scenario: an empty 15-minute window is a success
      Given timePeriod is "15min" with an empty select-time window
      When the host fetches
      Then zero rows is recorded as "usage/empty-window"
      And the run is considered successful

    Scenario: an empty dataset without an error is recorded as empty
      Given the endpoint returns valid JSON containing no readings
      Then zero rows is recorded
      And the run is considered successful
      And the failure is not reported as "session-expired"

  Rule: the on-demand read is best-effort

    Scenario: a throttled ODR call does not abort the run
      Given the ODR call fails or is throttled
      Then the failure class is "usage/odr-unavailable"
      And the run continues
      And the 15-minute and hourly paths are unaffected

    Scenario: the ODR meter read is not forced on every poll
      Given the scheduled run is not the first of the hour
      Then get_on_demand_read is not set
      And the 30-second interval limit is never approached
