# Paperless Triage (local model)

`paperless-triage` labels the documents that wait in the Paperless-ngx inbox. It
uses a small local model through the `paperless` profile of `llamactl` (see
[`local-llm.md`](local-llm.md)). You upload documents as usual, run one command,
and then review the results in Paperless.

## Components

| Path | Purpose |
|------|---------|
| `personal/.local/bin/paperless-triage` | The script. Stowed to `~/.local/bin`, which is on `PATH`. |
| `paperless` profile in `personal/.local/bin/llamactl` | NuExtract3 at Q4_K_M, 16384 context, temperature 0.2. A candidate profile, so it is not in `EVERYDAY_PROFILES`. |
| `~/.config/paperless-triage/config.json` | Server URL, 1Password item, and household notes. **Not tracked.** `~/.config` is stowed from this repo, so `.gitignore` excludes the directory. |

The script uses the Python standard library only. It needs `llamactl`, and the
1Password CLI (`op`, from the Brewfile) signed in.

## What it does

1. It finds documents with the `TRIAGE` tag (the inbox tag) that do not have the
   `AI Labeled` tag yet. If there are none, it exits before it loads a model.
2. If the `paperless` profile is not running, it runs `llamactl start paperless`. If
   the script started the model, it runs `llamactl stop` at the end.
3. For each document, it sends the OCR text and a template. The template lists the
   correspondents, document types, storage paths, and accounts from the server.
   Thinking is off.
4. If the answer is not usable, it tries once more with thinking on.
5. It checks each answer against the server's lists. It writes only the valid
   values, and it adds `AI Labeled`.

The model sets these values:

- Title.
- Correspondent. When no existing correspondent fits, the script creates a new one.
- Document type and storage path. It uses existing values only.
- Created date.
- The `Account` custom field.

The script sets these values from the document type, with the mapping in the
configuration file:

- Tags, from `type_tags`.
- The `Tax Year` custom field. The script keeps the model's tax year only for the
  types in `tax_year_types`.

`TRIAGE` stays on the document. A person reviews the document and removes it.

## Usage

```sh
paperless-triage                  # label everything waiting in TRIAGE
paperless-triage --dry-run        # show what it would do, write nothing
paperless-triage --limit 5        # stop after five documents
paperless-triage --doc 412        # one document, even if it is not in TRIAGE
paperless-triage --redo           # include documents already tagged AI Labeled
paperless-triage --only-missing   # skip documents that Auto matching labeled
paperless-triage --keep-running   # leave the model loaded afterwards
```

Each document takes about 2 to 4 seconds. In a test, 15 bank statements took 46
seconds. For a long run, keep the Mac awake:

```sh
caffeinate -i paperless-triage
```

If you stop a run with Ctrl-C, the documents that were done keep their labels. The
next run continues with the rest, because it skips `AI Labeled` documents.

## Configuration file

Make `~/.config/paperless-triage/config.json`. Set `PAPERLESS_TRIAGE_CONFIG` to use a
different path.

```json
{
    "url": "https://paperless.example.com",
    "op_item": "<1Password item ID that holds the Paperless username and password>",
    "self_names": ["<your name>", "<your business name>"],
    "type_tags": {
        "Tax Return": ["Taxes"],
        "Tax Form": ["Taxes"],
        "Invoice": ["Business"]
    },
    "tax_year_types": ["Tax Return", "Tax Form"],
    "household": [
        "Tax returns from \"<preparer name on the forms>\" are from <correspondent>."
    ]
}
```

- `url` and `op_item` are required. All other keys are optional.
- Use the 1Password item **ID**, not its name. Two items can start with the same
  name, and `op item get` then fails. To find the ID, run
  `op item list | grep -i paperless`.
- `self_names`: the names of your household and your business. A document that one
  of these names sent, for example your own invoice, is filed under its recipient.
- `type_tags`: the tags for each document type. The names must match the server.
- `tax_year_types`: the document types that get a `Tax Year`.
- `household`: each line goes into the instructions for the model. Use it for facts
  that the document text does not show, for example who a preparer works for.

## What the server needs

The script only uses labels that exist on the server. Make these in Paperless
before the first real run:

| Item | Requirement |
|------|-------------|
| `TRIAGE` tag | Marked as an inbox tag, so that every new document gets it. |
| `AI Labeled` tag | Matching set to **None**. If Auto matching adds it, the script skips documents that were never labeled. |
| `Family` and `Confidential` tags | Matching set to **None**. They control access, so Paperless and the model must not add them. |
| `Tax Year` custom field | Type integer. Optional. |
| `Account` custom field | Type select, one option per account. Optional. |
| Workflow for `Family` | Triggers "Document Added" and "Document Updated", with the filter "has tag Family". Action: give the other family account view and change permission. |

A dry run works without `AI Labeled`. If `AI Labeled` is missing, a real run stops
with an error. Without that tag, every run labels the same documents again.

## Workflow

### First import of many documents

1. Upload the documents. Leave out CSV and spreadsheet exports, and exact duplicate
   files. Paperless 3.x accepts duplicates by default.
2. Run `paperless-triage --limit 5` and check those documents in Paperless.
3. Run `caffeinate -i paperless-triage` for the rest.
4. In Paperless, filter on `AI Labeled`. Use bulk edit to add `Family` where it
   belongs, and to remove wrong tags.
5. Fix mistakes, then remove `TRIAGE`.

Do not use `--only-missing` for the first import. Auto matching has only learned
from the documents that are already on the server. It can give a new kind of
document a wrong correspondent, and `--only-missing` then skips that document.

### Everyday use

1. Upload new documents.
2. Run `paperless-triage --only-missing`.
3. Review `TRIAGE`, add `Family` where it belongs, and remove `TRIAGE`.

## Design decisions

### Why NuExtract3 and not the default model

The first version used the default profile, Qwen3.8-27B. It took 20 to 45 seconds
for each document and 13GB of memory, mostly for reasoning that this job does not
need.

[NuExtract3](https://huggingface.co/numind/NuExtract3-GGUF) is a 4B model from
NuMind, based on Qwen3.5-4B, for one job: fill a JSON template from a document. The
Q4_K_M file is 2.78GB. A template field can be a list of choices, so the server's
own lists go into the template. `llama-server` also gets the same shape as a JSON
schema, which it turns into a grammar. The answer is then always valid JSON, with
names spelled as they are on the server.

On NuMind's own extraction benchmark, NuExtract3 scored 0.651, Gemma-4-E4B 0.538, and
Qwen3.5-9B 0.479. That benchmark is not public yet. The test on this machine counts
more: on 15 bank statements, it set the correspondent, type, date, and account
correctly, in about 3 seconds each.

Two things to know about the profile:

- NuExtract3 is not a chat model. Use the default profile for `llamactl chat`.
- Its GGUF includes MTP layers, but `llama-server` logs them as unused tensors and
  ignores them. The profile therefore has no `DRAFTS` entry.

### Why tags and Tax Year come from the document type

In testing, NuExtract3 read senders, dates, and types reliably. It did not follow
judgment rules: it tagged ordinary bank statements as `Taxes` and `Business`, and gave
them a tax year, whatever the instructions said. A fixed mapping from document type
to tags cannot drift that way.

### Why the script asks for the sender and the recipient

For your own invoices and proposals, the correspondent is the client. When asked
for "the client", the model returned your own name. The script now asks for both
names. When the sender is in `self_names`, it uses the recipient.

### Why the script runs on the Mac and not through Paperless AI

Paperless-ngx 3.x has its own AI features, but the server must call the model.
`llamactl` binds `llama-server` to `127.0.0.1` on purpose: it has no API key and
CORS is open. The server cannot reach that address. A script on the Mac talks to
the model on loopback and to Paperless over HTTPS, and nothing new listens on the
network.

The script also does more than the Paperless "Suggest" button:

- The button works on one document per click. It does not run at upload.
- The button does not fill custom fields.

### Why the model cannot assign Family or Confidential

These tags decide who can see a document. A wrong answer from the model must not
share a private document. A person adds them during review.

### Why tags are only added, never removed

A tag on the document can come from a person at upload, or from Auto matching. The
script cannot tell which. Review is the step where wrong tags come off.

### Why the created date is set by the model

Paperless reads the first date in the text. Some statements print an older date
before the statement period, for example a "member since" date. The prompt
asks for the issue date, or the last day of the statement period.

### How Auto matching and the script work together

Paperless Auto matching learns the correspondent, document type, tags, and storage
path from labeled documents. It has two limits:

- It only learns from documents without an inbox tag. Remove `TRIAGE` after review,
  or it learns nothing.
- It retrains once each hour by default (`PAPERLESS_TRAIN_TASK_CRON`).

It does not learn titles, dates, or custom fields. `--only-missing` skips documents
that already have a correspondent and a document type, so the model only works on
documents that Auto matching did not recognize.

## Troubleshooting

| Symptom | Cause and fix |
|---------|---------------|
| `Error: llamactl is serving the 'default' profile` | A chat session uses the server. The script does not stop it for you. Run `llamactl stop`, then run the script again. |
| `first answer unusable (...), retrying with thinking on` | The first answer failed. The retry with thinking is slower. If it happens often, run `llamactl logs`. |
| `skipped: ValueError: empty answer (finish_reason length)` | The thinking retry used up the token budget. Raise `MAX_TOKENS_THINKING` in the script. |
| `skipped: ... no JSON object in answer` | The model answered in prose. Run the document again with `--doc <id> --redo`. |
| `Error: cannot read 'username' from 1Password item` | Run `op signin`, or check `op_item` in the configuration. |
| `Error: tag(s) ['AI Labeled'] do not exist` | Make the tag on the server, with matching set to None. |
| The model did not become ready in 15 minutes | Run `llamactl logs`. |
| Your own invoices are filed under your name | Add the name that is printed on them to `self_names`. |
| A tax form gets a date of January 1 | The form prints no issue date. The model then uses the start of the tax year. Fix the date during review. |
