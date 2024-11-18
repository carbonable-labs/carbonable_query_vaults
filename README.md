# Query Vault

Query Vault is a repository built to help backends and indexers retrieve specific on-chain data efficiently through Cairo smart contracts. Instead of relying on event-based indexing, it uses on-chain `get` functions to access data directly, ensuring continuous and reliable data retrieval.

## Key Features

- **Support for dApps**: Enables batch retrieval of data when a user connects to the application.
- **Indexer Replacement**: Acts as a fallback solution in scenarios such as:
  - The indexer is down.
  - There are issues with event data.
  - The indexer is undergoing a re-indexing phase.

By leveraging on-chain `get` functions, Query Vault avoids common pitfalls associated with event handling, offering a robust and scalable solution for developers working on decentralized applications and blockchain integrations.
