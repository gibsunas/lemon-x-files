@solaredge
@isotope
@failure-class-window
@z0-physical
@domain-utility-data
Feature: Isotope — solaredge/window

  The API documents a maximum range per granularity. This isotope is local and
  purely arithmetic, so a bad window is caught before a request is made — it
  should never reach the network.

  Background:
    Given the documented limits are
      | granularity | max days |
      | 15min       | 8        |
      | hour        | 31       |
      | day         | 90       |

  Rule: a window is validated before the request

    Scenario: a window within the documented limit
      Given granularity is "15min"
      And the requested range spans 8 days
      Then the window is allowed
      And the request is made

    Scenario: a window beyond the documented limit is split, not sent
      Given granularity is "15min"
      And the requested range spans 30 days
      When the host plans the request
      Then the range is split into windows of at most 8 days
      And no single request exceeds the limit

    Scenario: a window that cannot be split is refused
      Given the requested range is a single day
      And granularity is "month"
      Then the failure class is "window/too-wide"
      And no request is made

  Rule: an inverted range is a programming error, not a provider error

    Scenario: the end date precedes the start date
      Given the end date is before the start date
      Then the failure class is "window/inverted"
      And the run is refused
      And no request is made
