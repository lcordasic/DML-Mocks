# DML-Mocks

Apex project using **virtual DAO + constructor injection** for fast, DML-less unit tests. No external dependencies.

See the full technique documentation: [DML Mocking Technique Overview](docs/DML_MOCKING_TECHNIQUE_OVERVIEW.md).

## Quick Start

1. **Clone and authenticate**
   - Ensure [Salesforce CLI](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm) (`sf`) is installed.
   - Connect to a Dev Hub (for scratch orgs) or any target org.

2. **Deploy to a scratch org** (recommended)
   ```bash
   ./scripts/setup_scratch_org.sh dml-mocks DevHub
   ```
   This creates a scratch org, deploys metadata, and runs tests.

   **Or deploy manually:**
   ```bash
   sf org create scratch --definition-file config/project-scratch-def.json --set-default --alias dml-mocks
   sf project deploy start --source-dir force-app
   ```

3. **Run tests**
   ```bash
   sf apex run test --test-level RunLocalTests --result-format human --synchronous
   ```

## Prerequisites

- Salesforce CLI (`sf`) authenticated to a Dev Hub or sandbox
- A Salesforce DX workspace with the source deployed to the target org

> **Tip:** Use a scratch org for fast iteration and predictable metadata state.

## Source Layout

```
force-app/main/default/
  classes/
    ReadinessService.cls         Business logic with virtual DAOs
    ReadinessCalculator.cls
    RenewalReadinessController.cls
    OppyLineItemRenewalReadinessHandler.cls
    OpportunityRenewalReadinessHandler.cls
    RenewalReadinessTriggerState.cls
    RenewalReadinessBatch.cls
  classes/tests/
    TestDataReader.cls           In-memory SObject builders (no DML)
    ReadinessServiceTest.cls     DML-less unit tests with mock DAOs
    RenewalReadinessControllerTest.cls
    ... (other test classes)
  triggers/
    OpportunityRenewalReadiness.trigger
    OpportunityLineItemRenewalReadiness.trigger
  objects/
    Opportunity/                 Custom fields (RenewalReadinessStatus__c, etc.)
    OpportunityLineItem/
```

## Publishing to GitHub

The repo is initialized with an initial commit. To push to GitHub:

1. Create a new repository on [GitHub](https://github.com/new) (e.g. `DML-Mocks`).
2. Add the remote and push:
   ```bash
   git remote add origin https://github.com/YOUR_USERNAME/DML-Mocks.git
   git push -u origin main
   ```
3. Set the repository description (GitHub → Settings → General):
   > Apex project using virtual DAO + constructor injection for fast, DML-less unit tests. No external dependencies.

## Troubleshooting

- **Apex tests fail to run:** Ensure `sf org list` shows an authenticated org and that metadata is deployed.
- **Deploy fails:** Confirm the target org is set: `sf org display --target-org dml-mocks`
- **Setup script fails on login:** Run `sf org login web` manually first, then re-run the script.
