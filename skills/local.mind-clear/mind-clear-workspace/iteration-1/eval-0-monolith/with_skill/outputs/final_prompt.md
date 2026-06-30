You are a senior software architect writing a detailed technical specification.

<context>
The real problem is that a small B2B SaaS for agencies currently relies on shared credentials and manual database changes to grant and remove customer access. This creates onboarding delays, security risk, support overhead, and reduces customer trust. The target users are organization administrators at agency customers who need to invite and remove users without engineering help, plus invited organization members who need secure individual accounts. The desired outcome is an invite-only authentication system where an org admin can invite a teammate, the teammate can set a password, sign in, request a password reset, and access the product independently, while deactivated users lose access immediately.
</context>

<task>
Write a detailed technical specification for an invite-only B2B authentication and access-management feature based on the context above. Before writing each component section, reason through the design step by step inside <thinking> tags, including what the component must do, how it interacts with adjacent components, what failure modes matter, and how success will be verified. Then write the component section in the required output structure.
</task>

<constraints>
This feature includes only the first shippable slice: invite-only authentication and basic access management. Include email/password login, logout, password reset, organization-admin initiated invites, invite acceptance with initial password setup, user deactivation by organization admins, immediate session revocation on deactivation, and exactly two roles: org_admin and member.

Use a Node.js and TypeScript backend with PostgreSQL persistence, bcrypt for password hashing, secure server-managed session cookies for web authentication, and Postmark for transactional email delivery. Use single-use, time-limited tokens for both invite acceptance and password reset.

Keep the scope explicitly limited to authentication and access management. Treat open self-service signup, analytics, billing with Stripe, public API work, SSO, OAuth providers, advanced team management, and fine-grained authorization as separate follow-up efforts outside this specification.

Design for fewer than 500 organizations and fewer than 10,000 users in the first year. Target normal application responses within 500 ms excluding email delivery latency.
</constraints>

<components>
1. Identity and Credentials
- Single responsibility: store user identities, password hashes, account status, and credential verification behavior.
- Interface contract: inputs include email, password set or update actions, and account status changes; outputs include persisted identity records, password verification results, and status checks; side effects include password hash creation and updates.
- Dependencies: PostgreSQL, bcrypt.

2. Organization Membership and Roles
- Single responsibility: represent organization-scoped access and enforce org_admin versus member permissions.
- Interface contract: inputs include organization id, user id or invited email, role assignment, and membership status changes; outputs include membership lookups, duplicate-invite/member checks, and authorization decisions for admin-only actions; side effects include membership creation, activation, deactivation, and role persistence.
- Dependencies: Identity and Credentials, PostgreSQL.

3. Invite Flow
- Single responsibility: allow an org_admin to invite a user and allow that invitee to set an initial password through a secure tokenized flow.
- Interface contract: inputs include inviter identity, organization id, invitee email, target role, and invite token redemption data; outputs include invite creation results, token validation results, and completed invite acceptance results; side effects include Postmark email delivery requests, token issuance after provider acceptance, and token invalidation after use.
- Dependencies: Organization Membership and Roles, Identity and Credentials, Postmark.

4. Session Authentication
- Single responsibility: authenticate valid users and maintain secure authenticated sessions.
- Interface contract: inputs include login credentials, authenticated request context, and logout requests; outputs include login success or generic credential failure, authenticated session state, authorization context, and logout completion; side effects include session cookie issuance and session invalidation.
- Dependencies: Identity and Credentials, Organization Membership and Roles, session storage or equivalent session validation layer.

5. Password Reset Flow
- Single responsibility: let an existing user request a password reset and set a new password through a secure tokenized flow.
- Interface contract: inputs include account email, reset token, and new password; outputs include reset request handling results, token validation results, and password update results; side effects include Postmark email delivery requests, token issuance after provider acceptance, and token invalidation after redemption.
- Dependencies: Identity and Credentials, Postmark.

6. Deactivation and Session Revocation
- Single responsibility: prevent deactivated users from accessing the system and remove their active access immediately.
- Interface contract: inputs include org_admin deactivation actions, user status changes, and session lookups; outputs include updated access status and access-denied outcomes for deactivated users; side effects include immediate revocation of active sessions.
- Dependencies: Organization Membership and Roles, Session Authentication.

7. Abuse Protection and Error Handling
- Single responsibility: enforce rate limits and consistent safe error handling across authentication entry points.
- Interface contract: inputs include login attempts, password-reset requests, invite-token redemption attempts, and malformed or repeated requests; outputs include allow or block decisions and consistent user-facing error responses; side effects include rate-limit tracking.
- Dependencies: Invite Flow, Session Authentication, Password Reset Flow.

8. Email Delivery Integration
- Single responsibility: send invite and reset emails through Postmark and expose accepted or rejected delivery results to the calling flows.
- Interface contract: inputs include email type, recipient address, template data, and tokenized links; outputs include provider acceptance or rejection results plus error details suitable for application handling; side effects include external transactional email requests.
- Dependencies: Postmark, Invite Flow, Password Reset Flow.
</components>

<success_criteria>
- Identity and Credentials: given a valid password creation or update request, the system stores a bcrypt-hashed password and verifies it correctly on later login attempts.
- Organization Membership and Roles: given an org_admin action, the system authorizes invite and deactivation actions for org_admin users and rejects those same actions for member users.
- Invite Flow: given a valid org_admin invite request and Postmark acceptance, the system sends an invite email, creates a single-use time-limited invite token, allows exactly one successful redemption, and prevents reuse afterward.
- Session Authentication: given valid credentials for an active user, the system creates a valid authenticated session; given invalid credentials, it returns a generic credential error without revealing account existence.
- Password Reset Flow: given a valid reset request and Postmark acceptance, the system sends a reset email, creates a single-use time-limited reset token, allows password replacement exactly once, and blocks reuse afterward.
- Deactivation and Session Revocation: given a user deactivation event, the system prevents new logins for that user and invalidates existing sessions immediately.
- Abuse Protection and Error Handling: repeated login and password-reset attempts beyond the configured threshold are rate limited with deterministic responses.
- Email Delivery Integration: when Postmark rejects an invite or reset email request, the system reports the failure clearly to the caller and creates no usable invite or reset token.
- End-to-end feature validation: an org_admin can invite a teammate, the teammate can set a password, sign in successfully, request a password reset successfully, and lose access immediately after deactivation, with these flows covered by integration tests.
</success_criteria>

<edge_cases>
- Return a clear invalid-or-expired message when an invite token is expired or has already been used.
- Reject duplicate invites for the same email in the same organization with a deterministic already-invited or already-a-member response.
- Apply last-write-wins behavior for concurrent deactivate and reactivate actions in v1.
- Revoke active sessions immediately when a user is deactivated.
- Fail invite creation and password-reset initiation entirely when Postmark does not accept the email request, and create no usable token in those cases.
- Apply rate limiting to login attempts and password-reset requests.
- Return generic credential errors on failed login attempts to avoid account enumeration.
- Validate malformed or empty auth inputs with clear request-validation responses where appropriate, while preserving generic credential responses for login.
</edge_cases>

<output_format>
Structure the specification exactly as follows:

# Feature: Invite-Only B2B User Authentication

## Overview
Provide a concise 2-3 sentence summary of the feature, the problem it solves, and the expected business outcome.

## Components
For each component below, first include a <thinking> block with step-by-step reasoning, then write the component section.

### Identity and Credentials
#### Responsibility
#### Interface
#### Dependencies
#### Success Criteria
#### Edge Cases

### Organization Membership and Roles
#### Responsibility
#### Interface
#### Dependencies
#### Success Criteria
#### Edge Cases

### Invite Flow
#### Responsibility
#### Interface
#### Dependencies
#### Success Criteria
#### Edge Cases

### Session Authentication
#### Responsibility
#### Interface
#### Dependencies
#### Success Criteria
#### Edge Cases

### Password Reset Flow
#### Responsibility
#### Interface
#### Dependencies
#### Success Criteria
#### Edge Cases

### Deactivation and Session Revocation
#### Responsibility
#### Interface
#### Dependencies
#### Success Criteria
#### Edge Cases

### Abuse Protection and Error Handling
#### Responsibility
#### Interface
#### Dependencies
#### Success Criteria
#### Edge Cases

### Email Delivery Integration
#### Responsibility
#### Interface
#### Dependencies
#### Success Criteria
#### Edge Cases

## Dependencies
List the concrete technical dependencies used by this feature.

## Non-Goals
List the explicitly excluded follow-up areas: open signup, analytics, billing with Stripe, public API work, SSO, OAuth, advanced team management, and fine-grained permissions.

## Open Questions
State any genuine external decisions only if they are truly unresolved. If none remain, write "None."
</output_format>
