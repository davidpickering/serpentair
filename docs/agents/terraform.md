# Terraform tickets: the user builds from a recipe

This repo is the user's Terraform portfolio, so the user writes and applies the Terraform. The agent's deliverable on a Terraform ticket is a **recipe**: an ordered checklist of small steps, each with its code snippet, that the user types in, plans and applies one step at a time, learning how each piece behaves. The agent edits `.tf` files only when the user asks for that specific change.

## 1. Agree the split

At the start of the ticket, list the work and propose which parts are **scaffolding** the agent builds (undifferentiated plumbing: wrappers, wizards, docs, non-Terraform code) and which go in the recipe. Default everything under `infra/` to the recipe.

**Done when** the user has confirmed the split.

## 2. Write the recipe

Save it as `docs/recipes/<issue>-<slug>.md`, committed with the ticket. Open with the goal, the acceptance criteria it covers, and what any scaffolding already provides. Then the steps, in dependency order. Each step is one **increment**: 1–3 resources that plan and apply cleanly on their own, so state is consistent after every apply. Each step has:

- **Concept**: the one Terraform idea this step teaches, linked to its page on developer.hashicorp.com or the provider's registry docs.
- **File**: where the code goes.
- **Snippet**: the code to type. Use **fading**: the first time a pattern appears, give it in full; on repeats, give a hint instead ("same shape as step 3, for VIEWS") so the user writes it from memory.
- **Run**: the exact command, e.g. `infra/tf.sh prod plan` then `infra/tf.sh prod apply`.
- **Expect**: the plan summary (`Plan: 2 to add, 0 to change, 0 to destroy`) and what to look at afterwards (a Snowsight query, an `aws` read command, `terraform state show <address>`).
- **Check**: one question the user answers before moving on ("why does this grant need the securityadmin provider?").

Mark any step whose plan replaces or destroys something with **⚠ destructive** and say what is lost. Where a mistake teaches more than the right answer, add an optional **Experiment** ("remove `depends_on`, plan, read the error, put it back").

**Done when** the snippets, assembled in a scratch copy of the repo, pass `terraform fmt -check` and `terraform validate`, and every acceptance criterion in scope maps to a step.

## 3. Coach while the user builds

The user works through the recipe at their own pace. When they hit an error, start with a hint or a question that points at the cause; give the fix when they ask for it. When they finish a step or ask for a review, read their diff against the recipe and explain differences rather than rewriting them. Suggest a commit per step or small group, in the user's words, so the history shows the iteration.

**Done when** the user's own code gives a clean `plan` and the ticket's acceptance criteria are ticked; then run `/code-review` on their branch.
