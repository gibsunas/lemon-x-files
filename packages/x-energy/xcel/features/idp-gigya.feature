@xcel
@isotope
@failure-class-idp
@z0-physical
@domain-utility-data
Feature: Isotope — xcel/idp-gigya

  Gigya answers with a numeric errorCode. Each code is its own failure class
  because the remedy differs: a bad password is not a rate limit, and neither is
  an OTP challenge. Collapsing them into "auth failed" is what made the original
  65-run outage silent.

  Only errorCode 403042 is verified against the live API. The remaining codes are
  pinned on first live encounter and must not be guessed.

  Background:
    Given the Gigya data center is "us1"
    And the API key is the one published by the login page

  Rule: a rejected credential is refused, not retried

    Scenario: accounts.login rejects the password
      Given accounts.login returns errorCode 403042
      And errorMessage is "Invalid LoginID"
      Then the failure class is "idp/bad-credential"
      And the run is refused
      And the credential is not re-sent in this run

  Rule: an OTP challenge is a human-required state, not a retryable error

    Scenario: the IdP demands a verification code
      Given accounts.login reports a pending verification code
      Then the failure class is "idp/otp-required"
      And the run is refused with human required
      And the alarm states that a password alone cannot finish the flow

    Scenario: a locked account is not retried
      Given accounts.login reports the account is locked
      Then the failure class is "idp/account-locked"
      And the run is refused with human required

  Rule: transport failures defer instead of refusing

    Scenario: the IdP rate-limits the host
      Given accounts.login returns HTTP 429
      Then the failure class is "idp/rate-limited"
      And the run is deferred to the next scheduled interval
      And no alarm is raised on the first occurrence

    Scenario: the IdP is unavailable
      Given accounts.login returns HTTP 5xx
      Then the failure class is "idp/unavailable"
      And the run is deferred to the next scheduled interval

  Rule: success yields a session, and the credential is dropped

    Scenario: a valid credential returns a session
      Given accounts.login returns statusCode 200
      Then sessionInfo.sessionToken is present
      And the credential reference is dropped immediately after the call
      And the next isotope is xcel/oidc-handoff
