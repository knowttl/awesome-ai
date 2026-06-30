You are a senior software architect writing a detailed technical specification.

<context>
The feature is Post Likes v1 for a social app. The real problem being solved is that readers currently lack a lightweight way to express appreciation on posts, and posters lack fast feedback unless someone takes the higher-effort step of writing a comment. The target users are authenticated everyday users who browse and create posts in the app. The current state provides no quick feedback action on posts. The desired outcome is that an authenticated user can like or unlike a visible post with a single action, receive clear UI feedback, and see a like count that remains consistent with active likes after reload.
</context>

<task>
Write a detailed technical specification for Post Likes v1. Before writing each component section, reason through the component step by step inside <thinking> tags, including what it must do, how it interacts with other components, what can go wrong, how concurrency and idempotency affect it, and how it will be tested. After each <thinking> block, write the final specification content for that component using the required output structure.
</task>

<constraints>
Define the v1 scope as post likes only. Include the ability for a signed-in user to like and unlike a post. Require one active like per user per post. Treat guests as non-writable users who are prompted to sign in when they attempt to like. Enforce the app's existing post visibility and access rules before any like or unlike write is accepted. Allow users to like their own posts in v1. Use per-user like records as the source of truth instead of a blind counter mutation. Include a stored like count on the post as a read-optimized aggregate that is updated atomically with like record creation and deletion so the display count remains fast and correct. Define a v1 design that comfortably supports thousands of daily active users and hundreds of likes on a popular post. Explicitly define the following follow-up items as outside the v1 scope: comment likes, emoji reactions, notifications, activity feed changes, ranking changes, and cross-client real-time count synchronization.
</constraints>

<components>
1. Post Like Record Store
- Single responsibility: persist whether a specific user currently has an active like on a specific post.
- Interface contract: inputs are user identity, post identity, and a like state change request; outputs are the created or removed active-like state plus deterministic status for already-liked or already-unliked cases; side effects are durable creation or removal of the source-of-truth like record.
- Dependencies: authenticated user identity, post identity, post visibility/access validation, database storage with a uniqueness rule enforcing one active like per user per post.

2. Like/Unlike Write Path
- Single responsibility: accept like and unlike actions, validate permissions, execute idempotent writes, and coordinate the aggregate count update.
- Interface contract: inputs are an authenticated request to like or unlike a specific post; outputs are success or failure responses with the resulting liked state and count information needed by the client; side effects are transactional writes to the like record store and the stored count.
- Dependencies: authentication, authorization against post visibility, post existence checks, post like record store, count aggregate update mechanism, and error handling/reporting.

3. Like Count Aggregate
- Single responsibility: maintain and expose a fast display count that stays synchronized with active like records.
- Interface contract: inputs are successful like/unlike state transitions; outputs are the current displayable like count for a post; side effects are atomic increment or decrement updates that remain consistent with the source-of-truth records.
- Dependencies: post like record store, transactional update behavior, post storage, and post retrieval paths that display counts.

4. Client Like Button UI
- Single responsibility: let the user trigger like and unlike actions, render the current liked state and count, and communicate success or failure clearly.
- Interface contract: inputs are the current viewer state, current liked/unliked status for the viewed post, current like count, and responses from the write path; outputs are visible button state, displayed count, sign-in prompt behavior for guests, and error messaging; side effects are user-visible state transitions and UI reversion when a write fails.
- Dependencies: authenticated session state, post view data, like/unlike write path, and UI error/prompt patterns already used by the app.
</components>

<success_criteria>
- Post Like Record Store: given a visible post and an authenticated user with no existing active like, a like action creates exactly one active like record for that user/post pair; given an existing active like, an unlike action removes exactly that active like; repeated like or unlike submissions leave the store in the same correct end state without duplicate records.
- Like/Unlike Write Path: given an authenticated user and a visible post, a like request returns a success response with liked state true and the correct resulting count; an unlike request returns a success response with liked state false and the correct resulting count; given a guest or unauthorized viewer, the write path returns the correct non-write outcome and does not change stored data.
- Like Count Aggregate: after every successful like or unlike transition, the stored count changes by exactly one in the correct direction; after reload or fresh fetch, the count shown for a post matches the total number of active like records for that post.
- Client Like Button UI: a signed-in user can like and unlike with one direct action; a failed write causes the UI to revert to the prior state and show a clear error; a guest attempting to like is shown a sign-in prompt instead of a successful write state.
</success_criteria>

<edge_cases>
- When a user double-clicks the like control or the client retries the same request, the system resolves the action idempotently so there is still at most one active like record and the count is not incremented twice.
- When concurrent requests target the same post, the system preserves the one-active-like-per-user-per-post rule and keeps the stored count synchronized with the committed source-of-truth records.
- When a post is deleted, hidden, or otherwise becomes unavailable between render and click, the write path returns a clear failure result, no invalid like state is persisted, and the client reverts to the prior UI state.
- When persistence or transaction completion fails, the system returns a clear error outcome and the client shows the prior state plus an error message.
- When the acting user is a guest, the experience presents a sign-in prompt and does not attempt a successful like write.
- When the acting user lacks permission to view or interact with the post, the write is rejected consistently with the app's existing authorization rules.
- When the acting user is the author of the post, self-likes are accepted in v1.
- When other viewers are looking at the same post, the v1 experience does not require cross-client real-time synchronization; the spec should describe accurate count display on local actions and on subsequent fetch or reload.
</edge_cases>

<output_format>
Structure the spec exactly as follows:

# Feature: Post Likes v1

## Overview
Provide a 2-3 sentence summary describing the user problem, the target user, and the intended outcome.

## Components

### Post Like Record Store
#### Responsibility
#### Interface
#### Dependencies
#### Success Criteria
#### Edge Cases

### Like/Unlike Write Path
#### Responsibility
#### Interface
#### Dependencies
#### Success Criteria
#### Edge Cases

### Like Count Aggregate
#### Responsibility
#### Interface
#### Dependencies
#### Success Criteria
#### Edge Cases

### Client Like Button UI
#### Responsibility
#### Interface
#### Dependencies
#### Success Criteria
#### Edge Cases

## Dependencies
List the system dependencies and shared assumptions across components.

## Non-Goals
List the explicitly out-of-scope v1 items: comment likes, emoji reactions, notifications, activity feed changes, ranking changes, and cross-client real-time count synchronization.

## Open Questions
State “None” unless a genuine external decision remains outside the scope established above.
</output_format>
