# Odoo documentation

Locate and use the official Odoo functional and technical documentation.

## When to use

- During module development, to identify how to implement a feature, check proper syntax, and follow Odoo development idioms and guidelines.
- To understand business workflows, so the code and tests you write are workflow-aware and functionally correct.
- To validate whether a feature is functionally applicable to the target Odoo edition (Community vs. Enterprise).
- To answer questions about Odoo features, configuration, or development APIs.
- You need authoritative reference material for a specific Odoo version.

## Documentation sources

The official Odoo documentation is maintained in a public GitHub repository:

- Repository: https://github.com/odoo/documentation
- Branches: one per Odoo version (e.g., `19.0`, `18.0`, `17.0`)
- Developer reference and tutorials: `https://github.com/odoo/documentation/tree/<version>/content/developer`
- Functional app documentation: `https://github.com/odoo/documentation/tree/<version>/content/applications`

Replace `<version>` with the target Odoo version.

## Instructions

1. Determine the target Odoo version and what you need to know:
   - For implementation details, APIs, and coding patterns, use the developer documentation (`content/developer`).
   - For business logic, functional workflows, and feature applicability, use the application documentation (`content/applications`).
2. Use the URLs above to navigate the relevant branch and content area, or search the checked-out branch if the repository is cloned locally.
3. Apply what you find to:
   - Choose the right model, view, and API patterns.
   - Write correct Python/XML code and avoid deprecated idioms.
   - Understand the business workflow the module is part of.
   - Design workflow-aware tests that exercise realistic user scenarios.
4. For local access, clone the repository and check out the target branch:
   ```bash
   git clone https://github.com/odoo/documentation.git
   cd documentation
   git checkout <version>
   ```
5. Note that the `applications` documentation covers both Community and Enterprise features; Enterprise-only features may not be available in Odoo Community Edition.

## Output

The correct documentation URL or local path for the requested Odoo version and topic, plus any relevant guidance on how it applies to the feature or test at hand.
