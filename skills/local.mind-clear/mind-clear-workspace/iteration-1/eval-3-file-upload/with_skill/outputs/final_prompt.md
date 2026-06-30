You are a senior software architect writing a detailed technical specification.

<context>
An early-stage SaaS web application needs a secure self-service file handling feature for authenticated end users. Today users cannot manage their own profile pictures or account documents inside the product, so they rely on support or incomplete manual workarounds. The real problem is the lack of a trustworthy, user-scoped upload workflow for account-owned files. The desired outcome is that an authenticated user can upload a profile picture and private documents, see the files attached to their own account, and later retrieve only their own files through time-limited access while the system enforces validation, scanning, and cleanup.
</context>

<task>
Write a detailed technical specification for an initial release of this feature. Before writing each component's spec section, reason through it step by step inside <thinking> tags: what the component must do, which trust boundaries it crosses, which failure modes it handles, how it stays independently testable, and how its behavior is verified.
</task>

<constraints>
The initial release supports only authenticated end users of the SaaS product.
The initial release includes two file categories: one current profile picture per user, with JPEG and PNG support and a 5 MB limit; and private account documents, with PDF support and a 50 MB limit.
The system stores files in a private S3 bucket.
The system stores file metadata in the application database, including file id, owner user id, category, original filename, S3 object key, size, content type, lifecycle status, scan status, and timestamps.
The system uses direct-to-S3 uploads through presigned PUT URLs and short-lived presigned GET URLs for retrieval.
The system creates a pending database record before issuing an upload URL, finalizes the record only after the client calls a completion endpoint and the server verifies the object in S3, and uses scheduled reconciliation and cleanup for stale pending records and orphaned objects.
The system keeps files unavailable to end users until validation and malware scanning mark them clean and ready.
The initial release includes listing and downloading a user's own files, and replacing the current profile picture.
The initial release centers on owner-only access control with no cross-user sharing and no admin browsing workflow.
The scale target is low-thousands of users with ordinary SaaS concurrency, using single-request uploads up to 50 MB.
The specification should include later-phase capabilities as explicit non-goals for this release: admin moderation UI, bulk upload, document sharing, folder organization, file version history, and advanced media transformations.
</constraints>

<components>
1. Upload Initiation API
- Single responsibility: create a validated pending file record and issue a presigned S3 upload URL for an authenticated owner.
- Interface contract: input = authenticated user context plus requested file category, filename, declared size, and declared content type; output = file id, S3 object key, upload URL, upload expiry, and required client headers; side effects = inserts pending metadata record.
- Dependencies: auth or session layer, validation rules, database, and S3 signing client.

2. Client Upload Flow Contract
- Single responsibility: upload the file directly to S3 using the issued URL and then notify the backend that the upload attempt completed.
- Interface contract: input = upload URL package plus local file bytes; output = successful S3 PUT and completion request payload containing file id; side effects = stores object in S3 and triggers server-side finalization.
- Dependencies: upload initiation API, S3, and completion API.

3. Upload Completion and Finalization API
- Single responsibility: verify the uploaded object and transition the file record into the next safe lifecycle state.
- Interface contract: input = authenticated user context and file id; output = updated file record state; side effects = HEAD or metadata check against S3, status transition from pending_upload to pending_scan or ready, and association of profile picture reference only when the file is clean.
- Dependencies: database, S3 client, and lifecycle state rules.

4. Malware Scanning and Quarantine Workflow
- Single responsibility: inspect newly uploaded files and produce a clean or rejected scan decision before end-user access.
- Interface contract: input = newly uploaded object reference and file metadata; output = scan result state update; side effects = mark file ready when clean, mark file rejected when infected or unscannable, remove or quarantine rejected objects, and emit user-visible status.
- Dependencies: S3 event or queue trigger, scanning service or worker, and database.

5. File Access API
- Single responsibility: authorize owner-only access and issue short-lived presigned download URLs for ready files.
- Interface contract: input = authenticated user context and file id, plus list query parameters for file browsing; output = filtered file metadata list and or short-lived download URL; side effects = access audit events if the spec includes them.
- Dependencies: auth or session layer, database, and S3 signing client.

6. Profile Picture Assignment Logic
- Single responsibility: ensure the user's active profile picture points only to a ready, clean image and that replacement updates the single active reference.
- Interface contract: input = authenticated user context and ready image file id; output = updated user profile picture reference; side effects = supersedes the previous active profile picture association.
- Dependencies: user profile data model and file metadata model.

7. Lifecycle Reconciliation and Cleanup Job
- Single responsibility: resolve incomplete upload flows and keep storage and database state consistent over time.
- Interface contract: input = pending records and managed S3 objects older than a configured threshold; output = repaired or expired lifecycle states and deleted stale objects; side effects = deletes stale uploads, expires abandoned records, and flags reconciliation events.
- Dependencies: database, S3 listing, head, and delete operations, and a scheduler.

8. Authorization and Validation Policy
- Single responsibility: centralize file category rules, size and type checks, and owner scoping rules used by every entry point.
- Interface contract: input = user context, requested action, and file metadata; output = allow or deny decision plus normalized validation outcome; side effects = consistent error mapping.
- Dependencies: application auth model and configuration.
</components>

<success_criteria>
- Upload Initiation API: given an authenticated user and valid category metadata, the API creates a pending record and returns a presigned PUT URL within normal API latency; given an invalid type or oversize request, the API returns a clear validation error without creating a usable upload URL.
- Client Upload Flow Contract: given a valid upload URL and supported file, the client uploads directly to S3 and calls completion successfully; given an expired URL, the flow returns a recoverable message that prompts the user to request a new upload URL.
- Upload Completion and Finalization API: given an uploaded object whose size and content type match policy, the API verifies the object and advances the file to pending_scan; given a missing object or mismatched metadata, the API returns a clear failure and keeps the file unavailable.
- Malware Scanning and Quarantine Workflow: given a clean uploaded file, the workflow marks it ready and makes it eligible for retrieval; given an infected or unscannable file, the workflow marks it rejected, prevents download or profile-picture use, and removes or quarantines the object.
- File Access API: given a ready file owned by the requester, the API returns a short-lived presigned GET URL; given a file owned by another user, the API responds with an authorization-safe denial and never returns object details.
- Profile Picture Assignment Logic: given a ready clean image owned by the user, the profile record points to that file as the single active profile picture; given a non-image or non-ready file, the assignment is rejected.
- Lifecycle Reconciliation and Cleanup Job: given a pending record older than the expiry threshold, the job expires it and deletes any associated object; given an object that exists in S3 after an interrupted completion flow, the job either reconciles it to its pending record or deletes it after the grace period.
- Authorization and Validation Policy: every API path enforces the same category-specific size, type, and ownership rules in isolation tests and integration tests.
</success_criteria>

<edge_cases>
- When no file is selected, the initiation request returns a validation error that tells the client a file is required.
- When the declared or actual file type is outside the allowed set, the system rejects the upload and leaves no ready file record.
- When a profile picture exceeds 5 MB or a document exceeds 50 MB, the system rejects it with a clear size-limit error and keeps storage and database state clean.
- When a user attempts to access another user's file id, the system returns an authorization-safe denial and never exposes a reusable URL.
- When S3 upload succeeds but the database finalization step fails or the client never calls completion, the file remains in a non-ready lifecycle state and the reconciliation job resolves or deletes it.
- When the completion API is called before the object exists, the API returns a recoverable error and preserves the pending state.
- When malware scanning is still pending, the file is visible only as pending and is not downloadable or usable as a profile picture.
- When malware scanning fails, the file becomes rejected with a user-visible status explaining that the upload could not be accepted.
- When a user replaces a profile picture, the new clean image becomes active and the previous image loses active status without affecting document records.
- When two upload attempts happen concurrently for the same user, lifecycle state and ownership checks keep each file record isolated, and profile picture activation resolves to a single active image based on the defined update rule.
- When download URLs expire, the client requests a fresh presigned GET URL through the authorized access API.
- When the S3 object metadata does not match the initiated upload contract, finalization fails and the file never transitions to ready.
</edge_cases>

<output_format>
Structure the specification with these exact top-level headers:

# Feature: Authenticated Private File Uploads for Profile Pictures and Account Documents

## Overview
Provide a concise summary of the user problem, current manual workaround, and the secure self-service outcome.

## Architecture Summary
Describe the end-to-end flow from initiation through S3 upload, completion, scanning, access, and cleanup.

## Components

### Upload Initiation API
#### Responsibility
#### Interface
#### Dependencies
#### Success Criteria
#### Edge Cases

### Client Upload Flow Contract
#### Responsibility
#### Interface
#### Dependencies
#### Success Criteria
#### Edge Cases

### Upload Completion and Finalization API
#### Responsibility
#### Interface
#### Dependencies
#### Success Criteria
#### Edge Cases

### Malware Scanning and Quarantine Workflow
#### Responsibility
#### Interface
#### Dependencies
#### Success Criteria
#### Edge Cases

### File Access API
#### Responsibility
#### Interface
#### Dependencies
#### Success Criteria
#### Edge Cases

### Profile Picture Assignment Logic
#### Responsibility
#### Interface
#### Dependencies
#### Success Criteria
#### Edge Cases

### Lifecycle Reconciliation and Cleanup Job
#### Responsibility
#### Interface
#### Dependencies
#### Success Criteria
#### Edge Cases

### Authorization and Validation Policy
#### Responsibility
#### Interface
#### Dependencies
#### Success Criteria
#### Edge Cases

## Data Model
Include file metadata fields, lifecycle states, scan states, and the user profile picture reference.

## Authorization Model
Include owner-only rules for upload, list, download, and profile picture assignment.

## Lifecycle States
Describe state transitions for pending_upload, pending_scan, ready, rejected, expired, and superseded profile pictures.

## Dependencies

## Non-Goals
List the later-phase capabilities outside this release.

## Open Questions
List only genuine external decisions that remain after the spec is written; if the current context resolves all major decisions, state that no blocking open questions remain.
</output_format>
