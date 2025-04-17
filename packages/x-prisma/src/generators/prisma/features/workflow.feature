Feature: Machine Management
  As a system administrator
  I want to manage workflow machines
  So that I can define workflow behaviors and states

  Background:
    Given the system has machine management capabilities

  Scenario: Create a new machine
    When I create a machine with the following details:
      | name     | typename |
      | "Process" | "Standard" |
    Then a new machine should be created with a unique ID
    And the creation timestamp should be recorded
    And the machine should be available for workflow assignment

  Scenario: Update machine details
    Given a machine exists in the system
    When I update the machine with new details:
      | name           | typename       |
      | "Updated Name" | "Updated Type" |
    Then the machine details should be updated
    And the update timestamp should be refreshed

  Scenario: Configure machine initial state
    Given a machine exists in the system
    When I configure the initial state with:
      | defaultState   | defaultContext   | defaultInput   |
      | "IDLE"         | "{}"             | "{}"           |
    Then the machine should have its initial configuration set

Feature: Workflow Management
  As a process owner
  I want to create and manage workflows
  So that I can automate and track business processes

  Background:
    Given the system has workflow capabilities
    And at least one machine is configured

  Scenario: Create a new workflow
    Given a machine with ID "machine-123" exists
    When I create a workflow with the following details:
      | name      | typename  | originatorId | machineId    |
      | "Process" | "Standard" | "user-456"   | "machine-123" |
    Then a new workflow should be created with a unique ID
    And the workflow should be linked to the specified machine
    And the workflow should have a trace ID for observability
    And the workflow should not be finalized

  Scenario: Initialize workflow state
    Given a workflow exists in the system
    When I initialize the workflow with:
      | initialState | initialContext | initialInput |
      | "START"      | "{}"           | "{}"         |
    Then the workflow should have its initial state set
    And the current state should match the initial state

  Scenario: Finalize a workflow
    Given a workflow exists in the system
    When I mark the workflow as finalized
    Then the workflow should be set to read-only
    And no further events should be allowed on this workflow

Feature: Workflow Event Tracking
  As a system auditor
  I want to track workflow events
  So that I can monitor process execution and maintain audit trails

  Background:
    Given the system has workflow event tracking capabilities
    And at least one workflow is active

  Scenario: Record a workflow event
    Given a workflow with ID "workflow-789" exists
    When an event occurs with the following details:
      | name      | typename  | originatorId |
      | "Approve" | "Decision" | "user-123"   |
    Then a new workflow event should be created with a unique ID
    And the event should be linked to the workflow
    And the event should record start and end timestamps
    And the event should capture execution metrics

  Scenario: Track workflow state transitions
    Given a workflow event is being recorded
    When the machine state changes from "REVIEW" to "APPROVED"
    Then the workflow event should store:
      | machineState | machineContext | machineActions       |
      | "APPROVED"   | "{status:1}"   | ["COMPLETE","REJECT"] |
    And the workflow's current state should be updated

  Scenario: Calculate event execution metrics
    Given a workflow event has completed
    Then the system should calculate:
      | executionTime | executionCost |
      | "125ms"       | "10"          |
    And set an appropriate result expiration time

Feature: Workflow Event Relationships
  As a process analyst
  I want to track relationships between workflow events
  So that I can understand process flows and dependencies

  Scenario: Link sequential workflow events
    Given a workflow has a previous event with ID "event-123"
    When a new event occurs in the workflow
    Then the new event should reference the previous event ID
    And the workflow should update its current event reference

  Scenario: Trace workflow execution
    Given multiple events occur in a workflow
    Then all events should share the same workflow trace ID
    And each event should have its own trace ID for detailed monitoring
