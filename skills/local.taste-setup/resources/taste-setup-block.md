# Taste Developer (Optional Setup)

The project includes an optional Taste Developer skill that learns your coding
preferences, conventions, and style over time by observing which outputs you
accept, reject, or edit.

## Setup Prompt

On the first interaction with this project — detected by the absence of both
`.ai/taste/taste.md` (opted in) and `.ai/taste/SKIP` (opted out) — ask:

> "This project includes the Taste Developer skill, which learns your coding
> preferences and style over time. Would you like to enable it?"

Only prompt once. Gate the prompt with these file checks:
- `.ai/taste/taste.md` exists → already opted in, do not prompt.
- `.ai/taste/SKIP` exists → already opted out, do not prompt.
- Neither exists → this is the first interaction; prompt once.

### If Accepted

Create the `.ai/taste/` directory and empty `.ai/taste/taste.md` file if they
don't already exist, then load the `local.taste-developer` skill and follow its
full lifecycle: learning loop, self-repair layer, taste profile management, and
file formats.

### If Declined

Write `.ai/taste/SKIP` to suppress future prompts. The skill remains
installed — if the user later says "start taste" or "enable taste developer",
activate it and remove the SKIP file.
