Feature: Access Control Models

Background:
Given a system with multiple access control mechanisms
And users with various attributes, roles, and relationships
And resources with different protection requirements

# Role-Based Access Control (RBAC)
Scenario: Role-Based Access Control
Given a user with the "Manager" role
When the user attempts to access the "Financial Report"
And the "Manager" role has permission to access "Financial Report"
Then the system grants access

Scenario: RBAC permission denial
Given a user with the "Employee" role
When the user attempts to access the "Payroll System"
And the "Employee" role does not have permission to access "Payroll System"
Then the system denies access

# Attribute-Based Access Control (ABAC)
Scenario: Attribute-Based Access Control
Given a user with attributes:
| department | "Finance" |
| clearance  | "Level 2" |
| location   | "HQ"      |
When the user attempts to access a resource with required attributes:
| requiredDepartment | "Finance" |
| minClearance       | "Level 2" |
| allowedLocations   | "HQ, Branch" |
And the current time is within working hours
Then the system grants access

Scenario: ABAC policy evaluation
Given a user with attributes:
| department | "Marketing" |
| clearance  | "Level 1"   |
When the user attempts to access a resource with required attributes:
| requiredDepartment | "Finance, Marketing" |
| minClearance       | "Level 2"            |
Then the system denies access

# Relationship-Based Access Control (ReBAC)
Scenario: Relationship-Based Access Control - direct relationship
Given a user who is the "owner" of a document
When the user attempts to access the document
Then the system grants access

Scenario: ReBAC - indirect relationship
Given a user who is a "team member" of a project
And the project "contains" a document
When the user attempts to access the document
Then the system grants access

Scenario: ReBAC - relationship path
Given a user who is a "manager" of an employee
And the employee is the "owner" of a document
When the user attempts to access the document
And the system policy allows "manager-of-owner" relationship path
Then the system grants access

# Risk-Based Access Control (RiskBAC)
Scenario: Risk-Based Access Control - low risk
Given a user attempting to access a resource
And the system calculates the following risk factors:
| userTrustScore      | "High"     |
| resourceSensitivity | "Low"      |
| accessLocation      | "Corporate" |
| deviceTrustLevel    | "Managed"  |
| anomalyScore        | "Low"      |
When the calculated risk score is "Low"
Then the system grants access without additional verification

Scenario: RiskBAC - medium risk
Given a user attempting to access a resource
And the system calculates the following risk factors:
| userTrustScore      | "Medium"   |
| resourceSensitivity | "Medium"   |
| accessLocation      | "Remote"   |
| deviceTrustLevel    | "Personal" |
| anomalyScore        | "Medium"   |
When the calculated risk score is "Medium"
Then the system requires additional authentication
And the user provides the required authentication
Then the system grants access

Scenario: RiskBAC - high risk
Given a user attempting to access a resource
And the system calculates the following risk factors:
| userTrustScore      | "Low"      |
| resourceSensitivity | "High"     |
| accessLocation      | "Unknown"  |
| deviceTrustLevel    | "Unknown"  |
| anomalyScore        | "High"     |
When the calculated risk score is "High"
Then the system denies access
And the system logs the access attempt for security review

# Risk Factor Calculation Details
Scenario Outline: User Trust Score Calculation
Given a user with the following characteristics:
| loginHistory        | <loginHistory>        |
| securityIncidents   | <securityIncidents>   |
| accountAge          | <accountAge>          |
| mfaEnabled          | <mfaEnabled>          |
| privilegeLevel      | <privilegeLevel>      |
When the system calculates the user trust score
Then the user trust score should be <trustScore>

    Examples:
      | loginHistory | securityIncidents | accountAge | mfaEnabled | privilegeLevel | trustScore |
      | "Consistent" | "None"            | ">1 year"  | "Yes"      | "Standard"     | "High"     |
      | "Consistent" | "Minor"           | ">6 months"| "Yes"      | "Elevated"     | "Medium"   |
      | "Irregular"  | "Major"           | "<3 months"| "No"       | "Admin"        | "Low"      |

Scenario Outline: Resource Sensitivity Calculation
Given a resource with the following characteristics:
| dataClassification  | <dataClassification>  |
| regulatoryCompliance| <regulatoryCompliance>|
| businessImpact      | <businessImpact>      |
| accessFrequency     | <accessFrequency>     |
When the system calculates the resource sensitivity
Then the resource sensitivity should be <sensitivityLevel>

    Examples:
      | dataClassification | regulatoryCompliance | businessImpact | accessFrequency | sensitivityLevel |
      | "Public"           | "None"               | "Low"          | "High"          | "Low"            |
      | "Internal"         | "Moderate"           | "Medium"       | "Medium"        | "Medium"         |
      | "Confidential"     | "High (PII/PHI)"     | "Critical"     | "Low"           | "High"           |

Scenario Outline: Access Location Risk Calculation
Given an access attempt from location with characteristics:
| networkType         | <networkType>         |
| geographicLocation  | <geographicLocation>  |
| vpnUsage            | <vpnUsage>            |
| timeOfDay           | <timeOfDay>           |
When the system calculates the location risk
Then the location risk should be <locationRisk>

    Examples:
      | networkType   | geographicLocation | vpnUsage | timeOfDay      | locationRisk |
      | "Corporate"   | "Office"           | "N/A"    | "Business Hours"| "Corporate"  |
      | "Home"        | "Known Residence"  | "Yes"    | "Evening"       | "Remote"     |
      | "Public"      | "Unusual Country"  | "No"     | "Off-hours"     | "Unknown"    |

Scenario Outline: Device Trust Level Calculation
Given a device with the following characteristics:
| deviceType          | <deviceType>          |
| osPatched           | <osPatched>           |
| antivirusStatus     | <antivirusStatus>     |
| encryptionEnabled   | <encryptionEnabled>   |
| managementStatus    | <managementStatus>    |
When the system calculates the device trust level
Then the device trust level should be <deviceTrust>

    Examples:
      | deviceType  | osPatched | antivirusStatus | encryptionEnabled | managementStatus | deviceTrust |
      | "Corporate" | "Yes"     | "Active"        | "Yes"             | "Managed"        | "Managed"   |
      | "Personal"  | "Yes"     | "Active"        | "Yes"             | "Registered"     | "Personal"  |
      | "Unknown"   | "Unknown" | "Unknown"       | "Unknown"         | "Unmanaged"      | "Unknown"   |

Scenario Outline: Anomaly Score Calculation
Given an access attempt with the following characteristics:
| timeDeviation       | <timeDeviation>       |
| behavioralPattern   | <behavioralPattern>   |
| concurrentSessions  | <concurrentSessions>  |
| resourceAccessPattern | <resourceAccessPattern> |
| authenticationMethod| <authenticationMethod>|
When the system calculates the anomaly score
Then the anomaly score should be <anomalyScore>

    Examples:
      | timeDeviation | behavioralPattern | concurrentSessions | resourceAccessPattern | authenticationMethod | anomalyScore |
      | "Normal"      | "Typical"         | "Single"           | "Normal"              | "Standard"           | "Low"        |
      | "Off-hours"   | "Somewhat unusual"| "Multiple"         | "Unusual volume"      | "Standard"           | "Medium"     |
      | "Unusual"     | "Highly unusual"  | "Excessive"        | "Never accessed before" | "Failed attempts"  | "High"       |

Scenario: Final Risk Score Calculation
Given the following individual risk factors:
| userTrustScore      | <userTrustWeight> * <userTrustValue>       |
| resourceSensitivity | <resourceSensitivityWeight> * <resourceSensitivityValue> |
| accessLocation      | <locationWeight> * <locationValue>         |
| deviceTrustLevel    | <deviceTrustWeight> * <deviceTrustValue>   |
| anomalyScore        | <anomalyWeight> * <anomalyValue>           |
When the system calculates the final risk score as:
"""
finalRiskScore = (userTrustScore + resourceSensitivity +
accessLocation + deviceTrustLevel +
anomalyScore) / sumOfWeights
"""
Then the system categorizes the risk as:
| finalRiskScore < 0.3 | "Low"    |
| finalRiskScore < 0.7 | "Medium" |
| finalRiskScore ≥ 0.7 | "High"   |

