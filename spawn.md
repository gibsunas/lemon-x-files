# Spawning a seed

This repository is the location an agent or a CI job installs a ready-made template from, so that it
does not have to write the workspace by hand. `spawn.json` is the machine half of that: **the slots
an agent resolves, and the plan it runs once they are bound.**

It exists because the previous shape was a decision tree. A tree asks an agent to choose before it
has checked anything, and it asks the agent to hold the whole shape in its head while it does. An
agent spawning a seed has its hands full already. So: a handful of questions with defaults, three
branches that can run in parallel, and a small failure at the end of each one.

## The slots

Ask only what you cannot infer. Everything else has a default, and binding it is a decision.

| slot | the question | default |
| --- | --- | --- |
| `name` | what is the site called? (repository, folder and base path) | — required |
| `origin` | where will it be published? | `https://<owner>.github.io/<name>/` |
| `base` | what path is it mounted at? | `/<name>/` |
| `title` | the one line a reader sees | `<name>` |
| `start` | install a template, write the files, or use a CDN? | `install` |
| `checks` | which checks does the workspace claim? | `build`, `links` |
| `licence` | which licence? | `AGPL-3.0-only` |

Write the answers to `seed.json` and stop asking. A slot you cannot answer is a question for the
human, not a branch to explore.

**`checks` is the slot that matters most.** A workspace claims only what it will run, and a check
that is not claimed is recorded as not claimed. That is not the same as forcing every rule into a
small space: a site that inherits all of them can never show what breaking one looks like, and a
builder who never sees the failure never learns to decide.

## The plan

```
bind ──┬── start   ──┐
       ├── content ──┼── converge
       └── publish ──┘
```

Three branches, no order between them. Start the content while the install is still running; open
the repository before the first page is finished; run the deploy as soon as there is something to
publish. Each branch ends with a check and **a failure you provoke on purpose** — the smallest edit
that should turn it red. Run the provoke once. If the check stays green, the check is a sentence.

| branch | check | provoke |
| --- | --- | --- |
| `start` | one page serves at the bound base path | change `base` without changing the mount; the page must 404 its own assets |
| `content` | the page answers at its path with a title in the shell | rename the file without editing links; the guard names the broken link |
| `publish` | the deployed origin answers 200 for `/` and one deep link | push a failing type; the deploy stops rather than publishing |

Then converge: record what the workspace claims in `seed.json`, and run each claimed check once.

## When something fails

A branch failure is local. Fix it, re-run that branch's check, and leave the other two alone — that
is what the parallelism is for.

A converge failure is a claim that is not true. Fix it, or unclaim the check in `seed.json` **with a
reason**. Never unclaim by deleting the line: the record is what the next agent reads, and a claim
that quietly disappears is a guarantee nobody can audit.

## What this is not

Not a generator that owns the result. The template is cloned read-only, the generator never pushes,
and the workspace never learns what was generated. The slots are the only thing that crosses the
boundary, and they are recorded on the far side.
