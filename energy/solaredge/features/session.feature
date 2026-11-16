@solaredge
@isotope
@failure-class-session
@z0-physical
@domain-utility-data
Feature: Isotope — solaredge/session

  The session isotope reads a refresh token out of Safari's localStorage for
  monitoring.solaredge.com. It is the only SolarEdge isotope that touches a
  credential store, and it fails closed: with no token, nothing downstream runs.

  The token is read by the host through Safari, never copied to disk. Only key
  names may appear in a log record.

  Background:
    Given the storage keys are "se_refresh_token", "se_access_token",
      "se_cognito_client_id", "se_cognito_domain"
    And the monitoring host is "monitoring.solaredge.com"

  Rule: absence is visible

    Scenario: no tab on the monitoring host
      Given no Safari tab matches the monitoring host
      And the host is not permitted to open one
      Then the failure class is "session/no-tab"
      And the run is refused before any network call
      And the alarm says to open the site and sign in

    Scenario: a tab exists but carries no refresh token
      Given a Safari tab on the monitoring host
      And localStorage has no "se_refresh_token"
      Then the failure class is "session/not-signed-in"
      And the run is refused with human required

  Rule: Safari automation failure is distinct from a signed-out session

    Scenario: Safari refuses Apple Events
      Given Safari blocks JavaScript from Apple Events
      When the host reads localStorage
      Then the failure class is "session/safari-blocked"
      And the alarm names the Safari setting, not the account

  Rule: the token never leaves the browser unrecorded

    Scenario: only key names are logged
      When the host reads localStorage
      Then the log records the key names only
      And no token value appears in the log, argv, or the database
