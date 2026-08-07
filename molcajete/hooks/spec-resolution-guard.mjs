#!/usr/bin/env node
// Molcajete PreToolUse guard — spec-resolution-guard.mjs
//
// Refuses a Write or an Edit that puts an unresolved-item marker into a spec file.
// Registered by molcajete/hooks/hooks.json for Write(specs/**) and Edit(specs/**).
//
// The marker vocabulary below is the same vocabulary the `resolution-gate` shared
// skill documents. Change one and you must change the other.
//
// Contract
//   stdin  : the PreToolUse payload, { tool_name, tool_input: { ... } }
//   stdout : one PreToolUse hookSpecificOutput decision, or nothing at all
//   exit   : always 0. The decision travels in the JSON, never in the exit code.
//
// FAIL OPEN. Any parse error, any payload shape this file does not recognise, and
// any unreadable field allows the write. A guard that blocks on its own bug is
// worse than no guard.

const ALLOW_COMMENT = 'molcajete:allow-unresolved';
const SKIP_ENV = 'MOLCAJETE_SKIP_SPEC_GUARD';
const MAX_REPORTED = 5;

// Tier 1 — deny. Authoring-state markers. No Molcajete spec means anything by
// them. Uppercase and word-bounded on purpose: "tbd" inside prose is prose.
const DENY = [
  ['NEEDS CLARIFICATION', /NEEDS[ _-]?CLARIFICATION/i],
  ['TBD', /\bTBD\b/],
  ['TBS', /\bTBS\b/],
  ['TBR', /\bTBR\b/],
  ['FIXME', /\bFIXME\b/],
];

// Tier 2 — ask. Strings a spec can legitimately contain. A person decides.
//
// TODO sits here and not in DENY for one reason: `TODO:` is the literal section
// header of every specs/**/CHANGELOG.md (see the uc-log skill). Denying it would
// hard-block /m:spec, /m:plan and /m:build on their first changelog write.
const ASK = [
  ['TODO', /\bTODO\b/],
  ['to be <verb>', /\bto be (determined|decided|defined|specified|resolved)\b/i],
  ['???', /\?{3}/],
];

// The two TODO exemptions.
const TODO_HEADER = /^\s*TODO:\s*$/; // the changelog section header
const IS_CHANGELOG = /(^|\/)CHANGELOG\.md$/i; // and the whole changelog file

// Deliberately NOT matched, and each for a reason:
//   XXX      — FEAT-XXXX, UC-XXXX, SC-XXXX are the plugin's own ID placeholders
//   unknown  — "returns 404 when the user is unknown" is routine spec English
//   unclear, not sure, later, for now, open question, we should decide
//            — ordinary prose that a real requirement can need
// The resolution-gate skill calls these Tier 3 and checks them by reading.

function allow() {
  process.exit(0);
}

function decide(permissionDecision, permissionDecisionReason) {
  process.stdout.write(
    JSON.stringify({
      hookSpecificOutput: {
        hookEventName: 'PreToolUse',
        permissionDecision,
        permissionDecisionReason,
      },
    }),
  );
  process.exit(0);
}

// The content this tool call is about to introduce. Never the file on disk.
// Scanning the whole post-edit file would make it impossible to edit a file that
// already carries a marker — including editing it to remove the marker.
function incomingContent(input) {
  if (!input || typeof input !== 'object') return null;
  for (const key of ['content', 'file_text', 'new_string']) {
    if (typeof input[key] === 'string') return input[key];
  }
  if (Array.isArray(input.edits)) {
    return input.edits
      .map((e) => (e && typeof e.new_string === 'string' ? e.new_string : ''))
      .join('\n');
  }
  return null;
}

function scan(text, filePath) {
  const deny = [];
  const ask = [];
  const isChangelog = IS_CHANGELOG.test(filePath);
  let inFence = false;

  text.split(/\r?\n/).forEach((line, i) => {
    // Illustrative code and quoted standards live in fences. The build's own
    // completeness sweep already checks production files for TODO and FIXME.
    if (/^\s*(```|~~~)/.test(line)) {
      inFence = !inFence;
      return;
    }
    if (inFence) return;

    for (const [name, re] of DENY) {
      if (re.test(line)) deny.push({ name, n: i + 1, line });
    }
    for (const [name, re] of ASK) {
      if (name === 'TODO' && (isChangelog || TODO_HEADER.test(line))) continue;
      if (re.test(line)) ask.push({ name, n: i + 1, line });
    }
  });

  return { deny, ask };
}

function render(filePath, hits) {
  const shown = hits
    .slice(0, MAX_REPORTED)
    .map((h) => `  ${filePath}:${h.n}  ${h.name}  —  ${h.line.trim().slice(0, 100)}`)
    .join('\n');
  const rest = hits.length > MAX_REPORTED ? `\n  ... and ${hits.length - MAX_REPORTED} more` : '';
  return shown + rest;
}

const HATCH =
  `If this text is legitimate spec content, add the line\n` +
  `<!-- ${ALLOW_COMMENT} --> to the file, or set ${SKIP_ENV}=1 for this session.`;

async function main() {
  if (process.env[SKIP_ENV]) allow();

  let raw = '';
  for await (const chunk of process.stdin) raw += chunk;

  let payload;
  try {
    payload = JSON.parse(raw);
  } catch {
    allow();
  }
  if (!payload || typeof payload !== 'object') allow();

  const input = payload.tool_input || payload.toolInput;
  const filePath = (input && (input.file_path || input.filePath)) || '';
  if (typeof filePath !== 'string' || !filePath) allow();

  // Defence in depth. The `if` field in hooks.json is an optimization; this is
  // the guarantee. A misplaced or unsupported `if` cannot make this hook misfire
  // outside specs/**/*.md.
  if (!/(^|\/)specs\//.test(filePath)) allow();
  if (!/\.md$/i.test(filePath)) allow();

  const content = incomingContent(input);
  if (typeof content !== 'string' || content.length === 0) allow();
  if (content.includes(ALLOW_COMMENT)) allow();

  const { deny, ask } = scan(content, filePath);

  if (deny.length > 0) {
    decide(
      'deny',
      `Unresolved marker in a spec file:\n\n${render(filePath, deny)}\n\n` +
        `A Molcajete spec is baselined the moment /m:plan can read it. The next agent has no ` +
        `back-channel and cannot ask what the marker meant, so it guesses.\n\n` +
        `Resolve it before writing: ask the user for the value (see the resolution-gate and ` +
        `asking-questions skills), then write the answer as normal content. A decided default ` +
        `is allowed — write the value, the reason, and the fact that the user chose it. A hole ` +
        `is not.\n\n${HATCH}`,
    );
  }

  if (ask.length > 0) {
    decide(
      'ask',
      `Possible unresolved marker in a spec file:\n\n${render(filePath, ask)}\n\n` +
        `These strings are sometimes legitimate spec prose and sometimes an unresolved item. ` +
        `Approve if the text is real content. Reject and resolve it with the user if it is a ` +
        `decision still to be made.\n\n${HATCH}`,
    );
  }

  allow();
}

main().catch(() => process.exit(0));
