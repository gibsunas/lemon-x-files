@solaredge
@isotope
@failure-class-series
@z0-physical
@domain-utility-data
Feature: Isotope — solaredge/series

  Power and energy series. The dangerous failure is not an error but an empty
  result that is indistinguishable from a real one — which is why HTML, an API
  error object, and a genuinely empty series are three different classes.

  Background:
    Given the dashboard endpoints are "/services/dashboard/power/sites/{id}"
      and "/services/dashboard/energy/sites/{id}"
    And the client retries a 401 or 403 once after refreshing the token

  Rule: an auth failure is retried once, then reported

    Scenario: the bearer is stale
      Given a series request returns HTTP 401
      When the token is refreshed and the request is retried
      Then the retry succeeds
      And no failure class is recorded

    Scenario: the retry is also unauthorized
      Given a series request returns HTTP 401
      And the retry also returns HTTP 401
      Then the failure class is "series/unauthorized"
      And the run is refused with human required
      And the panels isotope is refused

  Rule: rate limiting is deferred, not failed

    Scenario: the provider rate-limits the host
      Given a series request returns HTTP 429 with Retry-After
      When the host waits and retries
      Then the retry is attempted once
      And if it is still 429 the failure class is "series/rate-limited"
      And the run is deferred to the next interval

  Rule: HTML is never parsed as data

    Scenario: an HTML body is returned
      Given a series request returns a body that is not JSON
      Then the failure class is "series/non-json"
      And no rows are written

    Scenario: the body carries an API error object
      Given a series request returns JSON containing "error"
      Then the failure class is "series/api-error"
      And the run is retried once
      And no rows are written

    Scenario: the provider rejects the request parameters
      Given a series request returns HTTP 400, 404, or 422
      Then the failure class is "series/rejected"
      And the run is not retried with the same parameters

  Rule: empty is not the same as failed

    Scenario: a valid response contains no readings
      Given a series request returns valid JSON with an empty series
      Then the failure class is "series/empty"
      And the run is considered successful
      And the failure is not reported as "series/non-json"
