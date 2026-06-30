---
**USER:** I need to add a 'like' button to posts in my social app. It's simple — just increment a counter in the database when clicked.

**AI:** That's the proposed implementation, not yet the problem. Phase 1 — Discovery: what problem does a like button solve for users, and what do users do today instead?

---
**USER:** People want a quick way to react to posts they enjoy. Right now they just scroll or leave a comment, which is a lot more effort for something small.

**AI:** Why is solving that worth doing now, and who is the primary user feeling this pain most?

---
**USER:** We want more engagement. Posters need feedback that people liked what they shared, and readers want a low-effort way to show appreciation. The main users are regular logged-in users posting and browsing every day.

**AI:** If v1 could support only one core action, what is the single most important user action here? And if visible like counts did not exist yet, would the feature still solve the main problem?

---
**USER:** The single most important action is tapping like on a post to show appreciation. Counts help with social proof, but even without them the core value is quick feedback.

**AI:** Good. I can now state the underlying need clearly: the real problem is that readers lack a lightweight feedback action, and posters lack quick signals that their posts resonated. The desired outcome is fast, low-friction appreciation on posts. Phase 2 — Interrogation: is v1 strictly post likes only, with comments, reactions, notifications, and ranking changes left for later? And should each user be limited to one active like per post?

---
**USER:** Yes, keep it to posts only for v1. No reactions or notification stuff yet. And yes, one like per user per post.

**AI:** I'd push back on “just increment a counter.” That falls apart on retries, double-clicks, and undo. Are you willing to make per-user like records the source of truth with a one-like-per-user-per-post rule? And should the feature handle race conditions/idempotency and let users unlike a post?

---
**USER:** Oh yeah, we'd need to handle double-clicks. Yes, users should be able to unlike. Using per-user like records makes sense.

**AI:** Who can like a post — authenticated users only? And what should happen when a guest or a user without access to a post tries to like it?

---
**USER:** Authenticated users only. Guests should be prompted to sign in, and if someone doesn't have access to the post then the like should be blocked.

**AI:** Do counts need to update in real time for every viewer, or is that a nice-to-have rather than a v1 requirement? And can users like their own posts in v1?

---
**USER:** Real-time count display would be nice but not required for v1. And self-likes are fine for now.

**AI:** What should the UI do if a like or unlike fails to persist? And how will you know this feature works in a concrete, testable way?

---
**USER:** If it fails, the button should revert and the user should see an error. I'd say it works if a user can like and unlike a post, double-clicking doesn't create duplicates, and after a reload the count matches the real number of likes.

**AI:** For read performance, should the displayed count come from a stored aggregate kept transactionally in sync with the like records, or be computed live every time? And roughly what scale should v1 comfortably handle?

---
**USER:** Let's use a stored count if we can keep it correct. Scale is pretty modest — maybe thousands of daily users, and a popular post might get a few hundred likes.

**AI:** One thing we still haven't nailed down: what happens if the post is deleted or becomes unavailable between render and click? And are activity feeds or notifications explicitly out of scope for this spec?

---
**USER:** If the post is gone or unavailable, return an error and revert the UI state. And yes, notifications and activity feed stuff are out of scope.

**AI:** Phase 3 — Verification

1. **The Real Problem**  
   Readers currently have no lightweight way to express appreciation on a post, and posters get no fast feedback signal unless someone spends the effort to comment. The feature exists to create low-friction feedback plus lightweight social proof.

2. **Target User**  
   Primary users are authenticated, everyday users of the social app who browse posts and want to acknowledge something quickly. Posters also benefit because they receive visible feedback that their content resonated.

3. **Desired Outcome**  
   An authenticated user can like or unlike a visible post with one action. The UI clearly reflects success or failure, and the displayed count remains consistent with the underlying active likes after reload.

4. **Scope**  
   **In scope for v1:** likes on posts, one active like per user per post, unlike support, guest sign-in prompt, authorization checks against existing post visibility rules, visible count display, and correct behavior under retries/double-clicks.  
   **Out of scope for v1:** comment likes, emoji reactions, notifications, activity feed changes, ranking/feed algorithm changes, and cross-client real-time updates.

5. **Architecture / Approach**  
   Use a per-user post-like record as the source of truth rather than blindly incrementing a counter. Enforce one active like per user per post. Maintain a stored like count on the post as a read-optimized aggregate, updated atomically with like creation/deletion so the fast display count stays correct.

6. **Components**  
   - **Post Like Record Store:** persists whether a specific user currently likes a specific post.  
   - **Like/Unlike Write Path:** validates auth and post access, creates/removes like records idempotently, and coordinates count updates.  
   - **Like Count Aggregate:** exposes a fast count for post display and stays synchronized with the source-of-truth records.  
   - **Client Like Button UI:** renders liked/unliked state, count display, optimistic or immediate interaction state, and error reversion behavior.

7. **Success Criteria**  
   - A signed-in user can like a visible post and the system ends with one active like record plus the count increased by exactly one.  
   - The same user can unlike that post and the system removes the active like record plus decreases the count by exactly one.  
   - Repeated clicks/retries do not create duplicate like records or inflate the count.  
   - Guests are prompted to sign in instead of creating likes.  
   - Users without access to a post cannot like it.  
   - After reload, the displayed count matches the active like records.

8. **Edge Cases & Constraints**  
   - Double-clicks and network retries must be handled idempotently.  
   - Concurrent writes must preserve one-like-per-user-per-post and a correct count.  
   - If the post is deleted or becomes unavailable between render and click, the write fails cleanly and the UI reverts with an error.  
   - If persistence fails, the UI reverts to the prior state and shows a clear error message.  
   - Self-likes are allowed in v1.  
   - Real-time cross-client count updates are not required for v1.  
   - The expected scale is modest: thousands of daily users and hundreds of likes on a hot post.

Please review the above. If everything looks correct, type **Confirmed** to proceed. Otherwise, tell me what needs to change.

---
**USER:** Confirmed

**AI:** ```
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
```

---
