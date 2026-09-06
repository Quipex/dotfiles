# global agent instructions

## Behavior

- Never use the em dash "-". Use plain dash "-" instead.
- Never use Unicode arrows or decorative symbols (e.g. "→", "⇒", "➜") in prose or comments. Use plain text ("leads to", "calls", "returns") or ASCII tokens that appear in real code ("->", "=>") instead. 
- never use tables in prose / markdown. instead, make complex lists with duplicated headers
- When writing commit messages, NEVER auto-add your agent name as co-author.
- When creating new branch, NEVER add your agent name in branch title.
- Never manually modify CHANGELOG.md files or any files marked as auto-generated.
- Apply high standard to engineering excellence: lint, test failures, and
  test flakiness. 
- When working in a project that is a subfolder of your home folder, ALWAYS read
  AGENTS.md, CLAUDE.md, GEMINI.md, and README.md to get familiar with the project.
- Всегда отвечай пользователю на русском языке, если он явно не попросил отвечать на другом языке.
- NEVER create PRs or post comments (on PRs, Jira, etc.) without explicit user
  permission. Always ask first.
- NEVER work directly in the root of a repository. Always create a feature branch using treehouse.
- Запрещено делать любые модификации файлов с помощью bash-скриптов (sed, perl и т.д.)
  без явного согласия пользователя. Разрешено использовать только встроенные
  инструменты редактирования (edit/write, replace/write_file и т.п.).
- Запрещено делать `git reset --hard` или любые другие деструктивные операции Git
  без прямого одобрения пользователем.
- Запрещено делать rebase. Агенты иногда зависают когда делают rebase. лучше делать merge и сохранять историю. Rebase можно делать только с явного одобрения.
- Запрещено изменять пул симуляторов iOS (создавать новые, удалять или изменять существующие симуляторы через xcrun simctl create/delete/erase и т.д.) без прямого разрешения пользователя. Разрешено только использовать уже существующие симуляторы из пула.
- используй treehouse чтобы создавать worktrees
- treehouse не имеет ограничения по размеру пула: просто бери новый
  worktree не думая о том, сколько их свободно

## Testing

- When writing or editing Mockito-based tests (Kotlin/Java), use the BDDMockito
  verification style: `then(mock).should().doStuff(...)` and
  `then(mock).shouldHaveNoMoreInteractions()` (or `then(mock).shouldHaveNoInteractions()`),
  NOT the imperative `verify(mock).doStuff(...)` / `verifyNoMoreInteractions(mock)` style.
  Prefer the BDD form for all new and edited tests.


---

## benjamin-plus (token-efficiency skill)

BENJAMIN-PLUS MODE ACTIVE

Every request you send re-reads the whole conversation so far. The bill is
steps × context, not words. Save by taking fewer steps and keeping bulky tool
output out of the transcript — never by skimping on the work itself. Solve the
task exactly as you otherwise would; these rules change how you look things
up, not what you build.

1. Recon in one pass.
   Before changing anything, collect every independent fact in a single step:
   chain probes with `;` and label the sections
   (`echo == layout ==; ls -la; echo == deps ==; head -30 requirements.txt`),
   or issue several tool calls in one message. A second lookup round is for
   questions the first round's answers created. Copying a convention (a DSL,
   schema, or file format)? Sample two existing examples of the exact construct
   you will write, not one.

2. Look through a keyhole.
   A command that only inspects ends with a limiter: `| head -50`, `| tail -20`,
   `grep -m 20`, `wc -l` before contents, Read with offset/limit. Size unknown?
   Measure first, then read the slice you need. Read a file whole only when you
   are about to edit it or copy from it verbatim. If a peek was too narrow,
   take exactly one wider look.

3. Probe the environment once.
   Before running code with several dependencies, test them in one probe
   (`python3 -c "import x, y, z"`; `command -v tool1 tool2`), and install
   everything missing in one command — not one traceback at a time.

4. Green means the task's own check.
   If the task names verification commands, those are the check: run them
   exactly as written, and green means exit status zero. A failure you judge
   environmental (missing package, compiler, or tool) is still your failure —
   fix the environment and re-run. The same check failing twice on the same
   approach means the approach is wrong: name one alternative and try it.
   When the check passes, stop.

5. Polling is a step.
   A running command that hasn't finished is not new information — but every
   status check re-reads the whole conversation. If your harness returns while
   a command is still running, wait in large slices (30 seconds or more;
   minutes for builds and test suites) before checking again. Never re-poll
   at one-second intervals, and never send empty input just to peek.

Never build a verification harness the task didn't ask for. If saving a step
risks a wrong result, spend the step: efficiency never outranks correctness.
