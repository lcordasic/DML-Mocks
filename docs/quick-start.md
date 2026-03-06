# Quick Start: DML-Mocks

Get from zero to a running scratch org and passing tests, then learn the virtual DAO mocking pattern.

In this quickstart you will:

- Connect to a Salesforce org and deploy the project
- Run Apex tests
- Understand the core patterns (virtual DAOs, constructor injection, in-memory SObjects)

---

## Prerequisites

- Salesforce CLI (`sf`) installed and authenticated
- A Dev Hub (for scratch orgs) or any target org you can deploy to

---

## Create or connect to an org

Choose one of the following:

### Use a scratch org

```bash
sf org login web --set-default-dev-hub --alias DevHub
sf org create scratch --definition-file config/project-scratch-def.json --set-default --alias dml-mocks
```

Or run the helper script (creates org, deploys, and runs tests):

```bash
./scripts/setup_scratch_org.sh dml-mocks DevHub
```

### Use an existing org

```bash
sf org login web --set-default --alias dml-mocks
sf config set target-org=dml-mocks
```

---

## Deploy the source

```bash
sf project deploy start --source-dir force-app
```

---

## Run the tests

Run all Apex tests:

```bash
sf apex run test --test-level RunLocalTests --result-format human --synchronous
```

Run a single test class:

```bash
sf apex run test --tests ReadinessServiceTest --result-format human
```

---

## Key concepts

This project uses **virtual DAO + constructor injection** for DML-less unit tests. See [DML Mocking Technique Overview](DML_MOCKING_TECHNIQUE_OVERVIEW.md) for the full documentation.

### Virtual DAO pattern

- Production services define inner `virtual` classes (e.g. `ReadinessService.OpportunityDAO`) that encapsulate SOQL and DML.
- Services expose an overloaded constructor that accepts DAO instances for tests.
- Tests subclass the DAO, override methods to return canned data and no-op DML, then inject via the constructor.

### In-memory SObjects

- Tests use `TestDataReader` to create SObjects with mock IDs (key prefixes like `006000000000001`).
- No `insert` or `update` in unit tests—data lives only in memory.

### Example reference

- Service: `force-app/main/default/classes/ReadinessService.cls`
- Unit test with mocks: `force-app/main/default/classes/tests/ReadinessServiceTest.cls`
- Test data helper: `force-app/main/default/classes/tests/TestDataReader.cls`

---

## Troubleshooting

- **Confirm target org:** `sf org display --target-org dml-mocks`
- **Re-run deploy:** `sf project deploy start --source-dir force-app`
- **Tests fail:** Ensure metadata is deployed and the org is authenticated.

---

## Next steps

- Read the [DML Mocking Technique Overview](DML_MOCKING_TECHNIQUE_OVERVIEW.md) for advantages, drawbacks, and when to choose this model.
- Apply the pattern to your own services: add virtual DAOs and constructor injection, then write DML-less unit tests.
