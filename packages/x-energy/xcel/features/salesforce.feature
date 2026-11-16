@xcel
@isotope
@failure-class-salesforce
@z0-physical
@domain-utility-data
Feature: Isotope — xcel/salesforce

  Salesforce is the boundary that finally sets SimpleSAMLAuthToken. A failure here
  means federation succeeded but the platform session did not — which is a
  different operator action from "the password is wrong".

  Background:
    Given the callback is "https://my.xcelenergy.com/MyAccount/services/authcallback/CustomPKCEEndpoint"
    And the usage page is "https://myenergy.xcelenergy.com/myenergy/usage-history"

  Rule: the session is proven, not inferred

    Scenario: a completed callback sets the platform session
      Given the callback returns a redirect
      When the host follows it with the cookie jar
      Then the jar holds "SimpleSAMLAuthToken"
      And GET the usage page returns HTTP 200 HTML containing the usage form

    Scenario: an error callback is a distinct class
      Given the callback lands on MA_Login_Error
      Then the failure class is "salesforce/callback-error"
      And the run does not proceed to the usage isotope

    Scenario: a redirect without a session token is not treated as success
      Given the callback returns a redirect
      And the jar does not hold "SimpleSAMLAuthToken"
      Then the failure class is "salesforce/no-session-token"
      And the run does not proceed to the usage isotope

  Rule: the session cookie is never written down

    Scenario: the jar lives in memory only
      When the session is established
      Then no cookie value is written to disk, argv, or the log
      And only cookie names may appear in a log record
