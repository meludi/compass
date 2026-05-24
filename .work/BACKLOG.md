# Backlog

<!-- 
Format for an entry:

- [] **Headline** — Description
-->

## Hohe Priorität

## Mittlere Priorität

- [ ] **Autonomous fix loops (DOCX gap)** — Vergleich gegen `autonomous-developer-workflow.docx` hat drei autonome Claude-fixt-und-commitet-Loops aufgezeigt, die beim Aufbau des Autonomy-Layers (`autonomy_mode`) bewusst ausgelassen wurden. Wenn sie eines Tages gebaut werden:
  - **Loop 1 — Pre-commit auto-fix (Husky):** Claude fixt fehlgeschlagene Tests, re-staged. Risiko: Tests können geschwächt oder gelöscht werden. Empfehlung: nicht bauen.
  - **Loop 2 — CI auto-fix:** `claude-review` Job editiert, commitet, pusht zurück zum PR-Branch. Risiko: Schreibzugriff aus CI, Push-Stürme, Budget-Explosion. Empfehlung: nicht bauen.
  - **Loop 3 — `@claude`-Mention-Trigger:** Neuer Workflow auf `issue_comment`, User-getriggert, wie Remote-`/implement`. Niedrigstes Risiko. **Empfehlung: wenn überhaupt, nur diesen Loop.**
  - Cross-cutting: max-retry-Cap pro PR, Commit-Tag für Audit (`[autofix]`/`[claude-mention]`), Opt-in über neue `autonomy_mode`-Stufe oder per-Loop-Flags, Konflikt-Handling, pre-flight Secret-Scan.
  - Voraussetzung Loop 2/3: `contents: write` Permission + Loop-Schutz (skip wenn letzter Commit von Claude).

## Nice to have
