---
**USER:** I want to build a platform with user authentication, a dashboard with analytics, team management, billing with Stripe, email notifications, and a public API. Can you help me spec this out?

**AI:** Phase 1 — Discovery.

You're describing six products, not one feature. That's exactly how teams end up with a vague spec and a stalled build.

Who is the primary user here, and what painful workaround are they using today?

---
**USER:** The primary user is probably small agencies using our SaaS product. Right now access is kind of hacked together — we share credentials in some cases, and if a customer needs someone added or removed we do it manually in the database. I want the whole platform because eventually they'll need analytics, billing, the works.

**AI:** Good, that helps.

Why is the shared-credential/manual-provisioning pain the one that matters most right now? What goes wrong for the business if you leave it alone for the next three months?

---
**USER:** Onboarding is slow, it's a security risk, and it makes us look immature when customers ask for basic account management. It also creates support work for us every time someone joins or leaves a client team. If we leave it alone, we probably keep losing time and it'll be harder to demo to larger customers.

**AI:** That's more concrete.

Why do these agencies need person-level access instead of one shared account? What outcome would make you say this problem is solved?

---
**USER:** Because there are usually multiple people involved — agency staff plus sometimes client-side stakeholders — and they shouldn't all share one login. I'd say it's solved if each person can have their own account, log in securely, reset their password, and an admin on the customer side can invite or disable people without asking us.

**AI:** Good. Now we're at the real problem.

The real problem is not "build a platform." The real problem is secure, self-serve access management for B2B customers so your team stops doing manual provisioning and customers stop sharing credentials.

Phase 2 — Interrogation.

If you could only ship one useful slice in two weeks, would you commit to authentication and access management first? What single user action matters most in v1?

---
**USER:** I still want this to become the foundation for team management, billing, and everything else. But yeah, if I had to narrow it, authentication first makes sense. The single most important action is: an org admin invites a teammate, that teammate sets a password, logs in, and gets access without us touching anything.

**AI:** That's the right cut.

Which authentication capabilities are actually in v1, and who is allowed to perform the admin actions?

---
**USER:** v1 should include email/password login, logout, password reset, org-admin invites, and the ability for org admins to deactivate users. Maybe very simple roles — basically admin and regular member. Admins do the invites and deactivation. I was originally thinking maybe open signup too, but I'm not sure.

**AI:** I'd push back on open signup here. For a B2B, org-invited product, open signup adds complexity and abuse surface without solving your immediate problem. Invite-only with just two roles is much easier to spec, build, and test.

Do you agree to exclude open signup and keep roles limited to **org_admin** and **member** for v1? What auth stack do you want to standardize on for this first version?

---
**USER:** Yeah, that's fair. Let's make it invite-only and keep just org_admin and member for now. For the stack, assume Node/TypeScript on the backend, Postgres for storage, bcrypt for passwords, and session cookies for auth. No OAuth or SSO yet.

**AI:** Good. That's a sane first version.

What should the system do when an invite token is expired or reused? And what decision are you making for brute-force login attempts or password-reset abuse?

---
**USER:** If an invite token is expired or already used, the user should see a clear invalid-or-expired message and the admin should be able to resend the invite. For abuse, rate limit login attempts and password reset requests. Also use generic login errors so people can't enumerate accounts.

**AI:** Good. One thing we haven't addressed yet is concurrency and testability.

What happens if two admins invite the same email or deactivate/reactivate the same user around the same time? Before we go further, how will you know this works in objective, testable terms?

---
**USER:** If the same email is invited twice for the same org, the second attempt should return something like already invited or already a member. For deactivate/reactivate at the same time, last write wins is probably fine for now. And I'd know it works if an admin can invite someone, the email goes out, the person sets a password, logs in successfully, password reset works, and deactivated users get blocked. We should be able to cover the main flows with integration tests.

**AI:** Good enough for a first spec, but we still need one more operational decision.

If Postmark doesn't accept an invite or reset email, do you want to fail the action entirely or create a pending token anyway? Also, when a user is deactivated, do existing sessions stay alive or get revoked immediately?

---
**USER:** Fail the action entirely. I don't want a usable token floating around if the email never got accepted by the provider. And deactivated users should get logged out immediately — revoke active sessions right away.

**AI:** Phase 3 — Verification.

## 1. The Real Problem
A small B2B SaaS is relying on shared credentials and manual database changes for customer access. That creates onboarding delays, security risk, support overhead, and weakens customer trust.

## 2. Target User
- **Primary operational user:** organization administrators at agency customers who need to invite and remove users without contacting engineering.
- **Secondary user:** invited organization members who need secure individual access.

## 3. Desired Outcome
An org admin can invite a teammate, the teammate can set a password and sign in with an individual account, password reset works reliably, and deactivated users lose access immediately — all without manual intervention from your team.

## 4. Scope
**In scope for v1**
- Invite-only authentication
- Email/password login
- Logout
- Password reset
- Org-admin initiated invites
- User deactivation by org admins
- Two roles only: `org_admin` and `member`
- Immediate session revocation on deactivation

**Explicitly out of scope for v1**
- Open self-service signup
- Analytics dashboard
- Billing / Stripe
- Public API
- SSO / OAuth
- Advanced team management
- Fine-grained permissions beyond the two roles

## 5. Architecture / Approach
- Backend: Node.js / TypeScript
- Database: PostgreSQL
- Password hashing: bcrypt
- Auth mechanism: secure server-managed session cookies
- Transactional email provider: Postmark
- Access model: organization-scoped membership with admin-controlled invites
- Token model: single-use, time-limited invite and reset tokens

## 6. Components
1. **Identity & Credentials** — stores users, password hashes, and account status.
2. **Organization Membership & Roles** — maps users to organizations and enforces `org_admin` vs `member` permissions.
3. **Invite Flow** — lets org admins invite users and lets invitees set their initial password.
4. **Session Authentication** — handles login, authenticated sessions, logout, and access checks.
5. **Password Reset Flow** — issues and redeems reset tokens securely.
6. **Deactivation & Session Revocation** — blocks deactivated users and invalidates active sessions immediately.
7. **Abuse Protection & Error Handling** — rate limits sensitive flows and returns consistent safe errors.
8. **Email Delivery Integration** — sends invite/reset emails via Postmark and gates token creation on provider acceptance.

## 7. Success Criteria
- Admin can invite a new user to their organization without engineering involvement.
- Invite email is accepted by Postmark, the invited user sets a password, and the token becomes unusable after redemption.
- User can sign in with email/password and receive a valid authenticated session.
- Login failures return generic credential errors.
- Password reset request sends a reset email, reset token works once, and the user can sign in with the new password.
- Deactivated users cannot sign in or continue using existing sessions.
- Duplicate invite attempts for the same email in the same org return a deterministic "already invited/member" style response.
- Core flows are covered by integration tests.

## 8. Edge Cases & Constraints
- Expired or reused invite tokens return a clear invalid/expired message.
- Login and password-reset flows are rate limited.
- Invite and reset actions fail entirely if Postmark does not accept the email; no usable token is created in that case.
- Duplicate invites for the same email in the same organization are rejected cleanly.
- Concurrent deactivate/reactivate actions use last-write-wins behavior for v1.
- Deactivation immediately revokes active sessions.
- Initial scale target: fewer than 500 organizations and fewer than 10,000 users in the first year.
- Normal application responses should target sub-500ms behavior, excluding email delivery latency.

Please review the above. If everything looks correct, type **Confirmed** to proceed. Otherwise, tell me what needs to change.

---
**USER:** Confirmed

**AI:** Phase 4 — Handoff Generation.

```text
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
```

---
