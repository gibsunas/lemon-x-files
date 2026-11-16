@xcel
@isotope
@failure-class-oidc
@z0-physical
@domain-utility-data
Feature: Isotope — xcel/oidc-handoff

  The OIDC boundary is where an accepted Gigya session must be recognized by the
  authorization server and exchanged for a code, then a token. PKCE is S256. A
  failure here is distinct from a credential failure: the credential was accepted,
  but the federation did not complete.

  This is the one handoff with an open question — whether a REST-created Gigya
  session is recognized by the OP without a browser writing the glt_ cookie.

  Background:
    Given the authorization endpoint is "https://apim.xcelenergy.com/v3/idp/authorize"
    And the token endpoint is "https://apim.xcelenergy.com/v3/idp/token"
    And the redirect URI is the Salesforce CustomPKCEEndpoint callback

  Rule: the authorize leg yields a code or an explicit error

    Scenario: an authenticated session is redirected with a code
      Given the cookie jar holds a session the OP recognizes
      When the host calls authorize with an S256 challenge
      Then the final redirect is authcallback/CustomPKCEEndpoint
      And the query carries "code"
      And the query "state" equals the value the host generated

    Scenario: an unrecognized session never yields a code
      Given the cookie jar holds no session the OP recognizes
      When the host calls authorize
      Then the redirect chain ends at MyAccount_Proxy
      And no "code" is present
      And the failure class is "oidc/no-session"

    Scenario: a returned state that does not match is discarded
      Given the callback carries a "state" the host did not generate
      Then the code is discarded unexchanged
      And the failure class is "oidc/state-mismatch"

  Rule: the token leg is checked, not assumed

    Scenario: an invalid code is a distinct class
      Given the token endpoint returns HTTP 400
      And detail is "The provided authorization code or refresh token is invalid."
      Then the failure class is "oidc/code-rejected"
      And the run does not retry with the same code

    Scenario: a PKCE mismatch is not retried
      Given the token endpoint rejects the code_verifier
      Then the failure class is "oidc/pkce-mismatch"
      And the alarm names the verifier/challenge pair, never a token
