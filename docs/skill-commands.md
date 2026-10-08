# Skill registration commands

These commands are **unreleased** and available in the source checkout. The
published 1.1.0 gem does not include them. See [local checkout usage](installation.md#run-from-a-local-checkout)
to run this implementation without replacing your installed gem.

Pubkit installs its bundled agent skills at a destination you choose. Commands
use local package files only: they do not fetch arbitrary skills, invoke an AI,
register an account, edit manuscripts or upgrade review sessions. Ruby 3.2 or
later and pubkit's Ruby dependencies are required; MeCab is not required here.

## List and install

```sh
asciidoc-pubkit skill list
asciidoc-pubkit skill list --json
asciidoc-pubkit skill install review-asciidoc-manuscript --agent codex
```

`list` describes the bundled skills. With `--json`, it also reports the
available pubkit version and packaged files. The initial bundled skill is
`review-asciidoc-manuscript`.
`install NAME --dir PATH` creates `PATH/NAME`, copying the bundled SKILL.md and
resources and recording their SHA-256 hashes in `.asciidoc-pubkit-skill.json`.
Missing parent directories are created. Paths are caller-relative, so run from
your manuscript directory or supply an absolute destination.

Choose exactly one destination option for `install`, `status` and `upgrade`:

| Option | Parent directory relative to the current working directory |
| --- | --- |
| `--agent codex` | `.agents/skills` |
| `--agent claude` | `.claude/skills` |
| `--dir PATH` | An explicit custom path (absolute paths are also accepted) |

For Claude Code, for example:

```sh
asciidoc-pubkit skill install review-asciidoc-manuscript --agent claude
asciidoc-pubkit skill status review-asciidoc-manuscript --agent claude
asciidoc-pubkit skill upgrade review-asciidoc-manuscript --agent claude
```

Both agents receive the same [Agent Skills format](https://agentskills.io/specification).
The specification defines skill contents, not their installation location.
These project paths follow the [Codex documentation](https://learn.chatgpt.com/docs/build-skills)
and [Claude Code documentation](https://code.claude.com/docs/en/skills).
`--agent` selects a destination only; it does not invoke an agent, detect a
running agent, change settings, or add agent-specific skill extensions. Run from
the project directory where you want the skill installed; pubkit does not search
for a repository root. `list` accepts neither destination option.

For personal installation, use an explicit directory such as
`--dir ~/.agents/skills` for Codex or `--dir ~/.claude/skills` for Claude Code.
There is no default destination when neither option is supplied, and combining
`--agent` with `--dir` is an error. Status and upgrade must select the same
location used for installation. Skill discovery is owned by the agent; you can
also ask it to read the installed SKILL.md explicitly, as shown in
[skill integration](skill-integration.md).

An existing destination, including an empty directory or manually copied skill,
is not overwritten or adopted. Use another destination for a managed copy.
Do not copy registration metadata onto a custom skill to bypass this check.
Symlink paths and symlink skill content are rejected. File names and resources
remain within the named skill directory; parent-level unrelated skills are kept.

## Inspect registration

```sh
asciidoc-pubkit skill status review-asciidoc-manuscript --agent codex
asciidoc-pubkit skill status review-asciidoc-manuscript --agent codex --json
```

Status is read-only and creates no directories. It compares installed file
contents and inventory against registration hashes and the current package.
Text output names changed files. JSON reports `name`, `destination`,
`available_version`, `installed_version`, `state`, and file-name arrays
`modified`, `missing`, `extra` and `updated`. `updated` identifies additions,
removals or content changes in the available bundle; it is not a text diff.

| State | Meaning |
| --- | --- |
| `current` | Registered files and version match the running pubkit bundle |
| `update-available` | Untouched registered copy differs from the running bundle or version |
| `modified` | Registered content was changed, removed or supplemented, including extra empty directories |
| `not-installed` | The destination does not exist |
| `unmanaged` | The destination exists without registration metadata |
| `newer-installed` | A newer pubkit version owns the unchanged installed copy; downgrade is blocked |

Malformed or unsupported metadata is an error, not an invitation to reset its
hashes. Registration metadata is a local ownership record, not a cryptographic
signature or proof that the skill was reviewed by an agent.

## Upgrade an unchanged skill

```sh
# Update pubkit deliberately after a new release becomes available.
gem update asciidoc-pubkit
asciidoc-pubkit skill status review-asciidoc-manuscript --agent codex
asciidoc-pubkit skill upgrade review-asciidoc-manuscript --agent codex
```

For a Bundler-managed project, update the selected gem and run these commands
through `bundle exec`. `upgrade` uses the bundle in the pubkit invocation you
actually run. It neither downloads a newer gem nor promises that this bundle is
the newest upstream version. A changed source checkout can also supply updates
at the same package version; file hashes identify those differences.

Only `current` and `update-available` copies can be upgraded. Current copies are
left unchanged. Locally changed, missing, unmanaged or newer-version copies are
rejected; there is no `--force` option. Keep author-specific style and terminology
in project instructions rather than editing the managed skill. To customize the
skill itself, keep a separately named copy and merge changes manually.

Installation and upgrade are serialized per parent directory using a temporary
`.asciidoc-pubkit-skills.lock` directory. New files are staged before replacing
the installed directory. A failed replacement restores the original; if restoring
also fails, the error reports the preserved backup path. A process interrupted
abruptly can leave a lock or staging directory. Check that no command is running
and preserve any backup before removing a stale lock or retrying.

Skill updates leave `manifest.json`, `document.json`, `findings.json` and
`baseline/` in existing review sessions unchanged. Continue an existing review
with its saved tool version and prompt. Start a different session to use newer
criteria; a new baseline cannot prove preservation against an earlier one.

| Exit code | Meaning |
| --- | --- |
| `0` | List/install/upgrade succeeded, or status is `current` |
| `1` | Status is another supported state; inspect its report |
| `2` | Invalid arguments, bundle, path, registration or file operation |

A status exit of 1 can mean an available update, not an installation failure.
These commands do not interactively ask to replace content or automatically
invoke an agent.

[Skill integration tutorial](skill-integration.md) · [Back to README](../README.md)
