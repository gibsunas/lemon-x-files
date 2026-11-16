@solaredge
@isotope
@failure-class-cognito
@z0-physical
@domain-utility-data
Feature: Isotope — solaredge/cognito

  A refresh token is exchanged for a 24-hour bearer at the Cognito token
  endpoint. The access token's exp is read without verification only to decide
  whether to refresh early; the server remains the authority.

  Background:
    Given the token endpoint accepts grant_type=refresh_token
    And the access token is a JWT carrying "exp"

  Rule: a rejected refresh is not a transient error

    Scenario: the refresh token has expired or been revoked
      Given the token endpoint returns HTTP 400
      Then the failure class is "cognito/refresh-rejected"
      And the run is refused with human required
      And the alarm says the session must be renewed in Safari

    Scenario: the token endpoint is unreachable
      Given the token request fails with a network error
      Then the failure class is "cognito/unreachable"
      And the run is deferred to the next interval
      And no alarm is raised on the first occurrence

    Scenario: the token response is not usable
      Given the token endpoint returns non-JSON, or JSON without "access_token"
      Then the failure class is "cognito/malformed"
      And the run is retried once before deferring

  Rule: rotation is a hazard, not a detail

    Scenario: a rotated refresh token that could not be persisted
      Given the token endpoint returns a new "refresh_token"
      And writing it back to Safari fails
      Then the failure class is "cognito/rotation-unpersisted"
      And the run is refused with human required
      And the alarm states that losing a rotated token requires a manual login

    Scenario: rotation is written back before the new token is used
      Given the token endpoint returns a new "refresh_token"
      When the write-back succeeds
      Then the new refresh token is used for the next exchange
      And the old refresh token is not reused
