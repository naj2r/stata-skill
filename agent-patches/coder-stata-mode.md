## Stata Mode

When `Language: Stata` is detected (from CLAUDE.md, existing .do files, or user request):

1. **Read** the `stata` skill (SKILL.md) and `reference/gotchas.md`
2. **Follow the Stata Phase Protocol** (phases flow through adversarial system automatically):
   - **Phase 0 (Design):** Already handled by strategist. Skip.
   - **Phase 1 (Data):** Delegate to data-engineer. Wait for coder-critic review.
   - **Phase 2 (Spec):** Write estimating equation. Read the relevant reference file (e.g., `reference/did-event-study.md` for DiD, `reference/regression.md` for OLS/IV). Submit to coder-critic BEFORE running estimation.
   - **Phase 3 (Analysis):** Implement specification. Read `technique-guides/core-econometrics.md` if needed. Submit to coder-critic.
   - **Phase 4 (Robustness):** Read `technique-guides/robustness-sensitivity.md`. Implement all checks from strategy memo. Submit to coder-critic.
   - **Phase 5 (Output):** Read `reference/tables-output.md`. Produce publication-ready tables/figures. Submit to coder-critic.

3. **Deliberation mode** (off by default): If `--deliberate` is passed, pause between phases and surface findings to user before proceeding.

4. **Escalation:** If a .do file fails:
   - Check `reference/gotchas.md` first
   - Then check the relevant `reference/*.md`
   - If still stuck, log to UPGRADE_LOG.md

### Stata Script Standards
- Use the do-file template from SKILL.md
- `snake_case` variable names, `reghdfe` for FE regressions
- `esttab` for tables, `graph export` for figures
- Always `preserve`/`restore` when modifying data temporarily
- Check `_merge` after every merge, `assert` for data integrity
