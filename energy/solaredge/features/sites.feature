@solaredge
@isotope
@failure-class-sites
@z0-physical
@domain-utility-data
Feature: Isotope — solaredge/sites

  The sitelist endpoint resolves which sites the account can see. An explicit
  --site-id is enough to continue when the sitelist itself is unavailable, which
  keeps a discovery failure from blocking a known site.

  Background:
    Given the sitelist endpoint is "/services/sitelist?status[]=ACTIVE"
    And the host may be given explicit site ids

  Rule: a discovery failure is not a data failure

    Scenario: the sitelist endpoint is unavailable
      Given the sitelist request fails
      And explicit site ids were supplied
      Then the failure class is "sites/unavailable"
      And the run continues with the supplied ids
      And metadata is filled in from the remaining endpoints

    Scenario: the sitelist request fails with no ids supplied
      Given the sitelist request fails
      And no explicit site ids were supplied
      Then the run is refused
      And the failure class is "sites/unavailable"

  Rule: absence is visible

    Scenario: the account sees no ACTIVE sites
      Given the sitelist returns an empty list
      Then the failure class is "sites/none-active"
      And the run is refused with human required
      And the alarm distinguishes "no sites" from "could not check"

    Scenario: an explicit site id is not visible to the account
      Given the sitelist returns sites
      And the requested site id is absent from them
      Then the failure class is "sites/not-visible"
      And the run is refused
      And the alarm names the missing id

    Scenario: the sitelist response is not a list
      Given the sitelist returns a JSON object rather than an array
      Then the failure class is "sites/malformed"
      And the run is retried once
