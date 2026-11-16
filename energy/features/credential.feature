@xcel
@isotope
@failure-class-credential
@z0-physical
@domain-utility-data
Feature: Isotope — xcel/credential

  The credential isotope is the only boundary that touches a secret. It fails
  closed: if the keychain cannot be read, no network request is attempted and no
  later isotope is consulted. A failure here is never retried in-process, because
  retrying cannot change the outcome — a human must act.

  Position: rung 0, distance 0. Any deviation refuses the run.

  Background:
    Given the sync host is the signed "adhd" binary (Identifier "adhd", Team "288ZTJGXX9")
    And the credential item is service "xcel-sync", account "gibsunas.co"

  Rule: the secret is read only by the trusted host

    Scenario: the signed host reads the credential silently
      Given the keychain ACL trusts the adhd binary
      When the host requests the credential
      Then the credential is returned without a SecurityAgent prompt
      And the value appears in no argv, stdout, or log record

    Scenario: the BAML binary cannot reach the credential
      Given the lattice binary is "isotope-baml" packed from pure BAML
      When it is asked for the credential
      Then it has no FFI and no keychain binding
      And the request is impossible rather than merely denied

    Scenario: an untrusted process cannot read the credential
      Given a process other than the trusted host
      When it runs "security find-generic-password -w -s xcel-sync"
      Then the request is denied or prompts the user
      And the run records a credential-isolation deviation

    Scenario: an explicit denial is its own class
      Given the trusted host requests the credential
      And SecurityAgent refuses the request
      Then the failure class is "credential/denied"
      And the run is refused with human required

  Rule: absence is visible

    Scenario: a missing item refuses the run
      Given the item "xcel-sync" does not exist
      When the host requests the credential
      Then the run is refused before any network call
      And the failure class is "credential/missing"
      And the alarm names the exact "security add-generic-password" remedy

    Scenario: an iCloud item is not mistaken for a readable one
      Given the only matching item lives in the iCloud Keychain
      When the host requests the credential
      Then the result is "credential/missing"
      And the alarm says "security" cannot search synchronizable items

    Scenario: signing drift is reported, not retried
      Given the host binary's code identity changed since the ACL grant
      When the host requests the credential
      Then the failure class is "credential/acl-drift"
      And the alarm says the signing identity, not the password, must be re-granted
