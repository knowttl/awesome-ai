You are a senior software architect writing a detailed technical specification.

<context>
A 12-person startup currently tracks work in a shared Google Sheet that is often stale. Team leads, project owners, and engineers do not have a reliable view of who owns which task, when it is due, or which tasks are overdue. Weekly standups are chaotic because nobody can quickly see current ownership and status. The feature to specify is the smallest useful replacement for the sheet: an internal task ownership and overdue tracker that gives every task a clear owner and due date, makes overdue work immediately visible, and reduces dropped tasks. Primary users are the team lead and project owners who assign work, plus engineers who need a clear view of their assigned tasks and can update task status.
</context>

<task>
Write a detailed technical specification for an internal web application feature called "Task Ownership and Overdue Tracker." Before writing each component's spec section, reason through it step by step inside <thinking> tags: what the component must do, what could fail, how it interacts with other components, and how it will be tested. Then write the component section using the required output format.
</task>

<constraints>
Version 1 is intentionally narrow. It replaces the shared Google Sheet rather than syncing with it. It supports task creation, task assignment, due dates, task status updates, and a clear overdue view. It uses existing company Google login rather than separate passwords. Team leads and project owners can create and edit tasks. All team members can view tasks. Assignees can update task status on tasks assigned to them. The system is designed for an internal team of 12 people and approximately 150–200 active tasks at a time. The architecture should favor a simple internal web app with a central task store, straightforward role-based permissions, and minimal operational complexity. It does not include roadmap planning, team chat, document collaboration, task dependencies, time tracking, reporting beyond overdue visibility, or external integrations beyond Google login.
</constraints>

<components>
1. Authentication and Access Control
- Single responsibility: Authenticate employees with Google and enforce who can view, create, edit, and update tasks.
- Interface contract: Inputs are Google login responses, authenticated user identity, and requested actions on task resources. Outputs are authenticated sessions and authorization decisions. Side effects include session creation and access-denied responses.
- Dependencies: Google identity provider, user/session storage, and task authorization rules.

2. Task Record and Persistence
- Single responsibility: Store the canonical task data needed for assignment, due-date tracking, status, and audit metadata.
- Interface contract: Inputs are create, read, update, and list requests for task records. Outputs are validated task records containing task identifier, owner, due date, status, last updated timestamp, and last updated by. Side effects include persistent writes and metadata updates.
- Dependencies: persistence layer, validation rules, and authenticated user context.

3. Task Creation and Editing Workflow
- Single responsibility: Provide the create/edit experience with required-field validation and clear save feedback.
- Interface contract: Inputs are task form submissions from authorized users. Outputs are validation results, saved task records, and user-visible success or error messages. Side effects include creating or updating task records and recording editor/timestamp metadata.
- Dependencies: authentication and access control, task persistence, and validation rules.

4. Task List and Overdue View
- Single responsibility: Present the current task list with clear owner, due date, status, and overdue visibility for standups and daily use.
- Interface contract: Inputs are list and filter requests from authenticated users. Outputs are task collections with owner, due date, status, overdue indicators, and views that make overdue work easy to spot. Side effects are limited to normal read activity.
- Dependencies: task persistence, authentication and access control, and overdue evaluation logic.

5. Overdue Evaluation and Concurrency Metadata
- Single responsibility: Determine when a task is overdue and expose the latest update metadata so simultaneous edits remain understandable.
- Interface contract: Inputs are task due date, current date/time, task status, and update operations. Outputs are overdue flags and last-updated metadata showing editor and timestamp. Side effects include updating the visible current state after saves.
- Dependencies: task persistence, application timezone configuration, and task update events.
</components>

<success_criteria>
- Authentication and Access Control: A company user signs in with Google and reaches the app without creating a separate password. A team lead or project owner creates and edits tasks successfully. An assignee updates status on their own assigned task successfully. An unauthorized edit attempt returns a clear access-denied result and leaves the task unchanged.
- Task Record and Persistence: Creating or updating a task stores and returns the canonical fields needed for standups: task identifier, owner, due date, status, last updated timestamp, and last updated by. Listing tasks reflects the latest saved data consistently.
- Task Creation and Editing Workflow: A task cannot be created or saved without an owner and due date. The UI returns clear validation messages for missing required fields. A successful save shows the updated owner, due date, status, timestamp, and editor information.
- Task List and Overdue View: Any authenticated team member opens the task list and sees current tasks with owner, due date, status, and overdue state. Overdue tasks are visually distinct and can be filtered or grouped so weekly standups can focus on them quickly. One screen is sufficient to identify task ownership and lateness without ambiguity.
- Overdue Evaluation and Concurrency Metadata: A task that is not completed becomes overdue at the start of the next day after its due date. A completed task is not shown as overdue in current views. If two users edit the same task close together, the system preserves the last saved version and shows the latest editor and timestamp so users can understand what happened.
- End-to-end business outcome: In normal weekly use, the team reviews the task list before standup, confirms every active task has an owner and due date, spots overdue tasks immediately, and conducts standup in under 10 minutes.
</success_criteria>

<edge_cases>
- When an authorized user submits a task without an owner, the system returns an inline validation error that clearly states an owner is required and preserves entered form data for correction.
- When an authorized user submits a task without a due date, the system returns an inline validation error that clearly states a due date is required and preserves entered form data for correction.
- When the current date passes the due date boundary and the task is not completed, the system marks the task overdue automatically starting at 00:00 on the next day.
- When a task is completed after previously becoming overdue, the system removes the active overdue indicator from current views while retaining the task’s update metadata.
- When Google authentication fails, the system returns the user to the sign-in flow with a clear authentication error and continues using Google login as the access path.
- When a user without edit permissions attempts to create or modify a task, the system returns a clear authorization error and preserves the existing task data unchanged.
- When two users save edits to the same task in close succession, the system accepts the last successful save as the current record and displays the latest updated timestamp and editor on the task view.
- When the task list contains up to 200 active tasks, the system presents the current list and overdue filters reliably for day-to-day team use.
</edge_cases>

<output_format>
Structure the spec as follows:

# Feature: Task Ownership and Overdue Tracker

## Overview
Provide a concise summary of the internal problem, the target users, and the narrow version-1 outcome.

## Components

### Authentication and Access Control
#### Responsibility
#### Interface
#### Dependencies
#### Success Criteria
#### Edge Cases

### Task Record and Persistence
#### Responsibility
#### Interface
#### Dependencies
#### Success Criteria
#### Edge Cases

### Task Creation and Editing Workflow
#### Responsibility
#### Interface
#### Dependencies
#### Success Criteria
#### Edge Cases

### Task List and Overdue View
#### Responsibility
#### Interface
#### Dependencies
#### Success Criteria
#### Edge Cases

### Overdue Evaluation and Concurrency Metadata
#### Responsibility
#### Interface
#### Dependencies
#### Success Criteria
#### Edge Cases

## Dependencies
List the external and internal dependencies needed for version 1, including Google login and the chosen persistence approach.

## Non-Goals
List the explicitly excluded version-1 items: roadmap planning, team chat, document collaboration, task dependencies, time tracking, advanced reporting, and sheet synchronization.

## Open Questions
List only genuine decisions that must come from stakeholders outside this spec. If the verified context leaves no such decisions, state that there are no open questions for version 1.
</output_format>
