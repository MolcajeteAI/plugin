---
description: Perform comprehensive security audit using multiple tools
---

IMPORTANT: Immediately use the Task tool with subagent_type="sol:auditor" to delegate ALL work to the auditor agent. Do NOT do any analysis or work in the main context.

Use this exact prompt for the agent:
"Execute the security audit workflow following these steps:

1. **Identify Contracts in Scope**
   - Use Glob to find all contracts: `src/**/*.sol` or `contracts/**/*.sol`
   - List all contracts that will be audited
   - Understand contract purposes from NatSpec and code structure

2. **Run Automated Security Analysis**
   - Follow **security-audit** skill methodology
   - Run Slither for static analysis:
     ```bash
     slither . --json slither-report.json
     slither . --detect reentrancy-eth,unchecked-transfer,dangerous-strict-equalities
     ```
   - Run Mythril if available:
     ```bash
     myth analyze contracts/*.sol -o json > mythril-report.json
     ```
   - Run Echidna for fuzzing if configured:
     ```bash
     echidna-test contracts/MyContract.sol --config echidna.yaml
     ```
   - Run Foundry fuzz tests:
     ```bash
     forge test --fuzz-runs 10000
     ```

3. **Perform Manual Code Review**
   - Use security-audit skill checklists:
     - Common vulnerabilities checklist (reentrancy, access control, integer issues, external calls, oracle manipulation, front-running, DoS, timestamp dependence, delegatecall, signature replay)
     - Access control checklist (admin protection, role checks, privilege escalation, multi-sig, timelock)
     - Token-specific checklist if applicable (ERC compliance, approval race, transfer checks, fee-on-transfer, decimals)
     - DeFi-specific checklist if applicable (oracle manipulation, flash loans, price staleness, slippage, liquidation)
     - Upgrade-specific checklist if upgradeable (storage layout, initializers, authorization, storage gaps, upgrade testing)
   - Review code manually for logic errors and business logic issues

4. **Classify All Findings by Severity**
   - **Critical**: Direct loss of funds, contract takeover, unauthorized state manipulation
   - **High**: Significant loss under specific conditions, privilege escalation, critical function DoS
   - **Medium**: Partial loss of funds, temporary DoS, front-running opportunities
   - **Low**: Gas optimizations, code quality issues, minor edge cases
   - **Informational**: Best practice recommendations, documentation improvements, code clarity

5. **Generate Comprehensive Audit Report**
   - Follow security-audit skill report template
   - Include:
     - Executive Summary (overall assessment, critical findings, recommendations)
     - Scope (contracts audited, tools used, audit date)
     - Findings (grouped by severity with file, lines, description, proof of concept, recommendation for each)
     - Summary (counts by severity)
     - Recommendations (prioritized actions)
   - For each finding provide:
     - Severity classification
     - File and line numbers
     - Detailed description
     - Proof of concept code if applicable
     - Specific, actionable remediation recommendation

6. **Create Summary Report**
   - Display summary with counts:
     ```
     Security Audit Summary:
     - Critical: X
     - High: X
     - Medium: X
     - Low: X
     - Informational: X
     ```
   - Highlight critical and high severity findings
   - Provide next steps and recommendations

Follow your agent instructions in agents/auditor.md and reference the security-audit skill and all relevant checklists."
