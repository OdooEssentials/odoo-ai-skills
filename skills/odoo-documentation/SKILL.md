# Odoo documentation

Locate and use the official Odoo functional and technical documentation.

## When to use

- You need authoritative reference material for an Odoo version.
- You are answering a question about Odoo features, configuration, or development APIs.
- You need to verify whether a feature is available in Odoo Community Edition.

## Documentation sources

The official Odoo documentation is maintained in a public GitHub repository:

- Repository: https://github.com/odoo/documentation
- Branches: one per Odoo version (e.g., `19.0`, `18.0`, `17.0`)
- Developer reference and tutorials: `https://github.com/odoo/documentation/tree/<version>/content/developer`
- Functional app documentation: `https://github.com/odoo/documentation/tree/<version>/content/applications`

Replace `<version>` with the target Odoo version.

## Instructions

1. Determine the target Odoo version.
2. Use the URLs above to navigate the relevant branch and content area.
3. For local access, clone the repository and check out the target branch:
   ```bash
   git clone https://github.com/odoo/documentation.git
   cd documentation
   git checkout <version>
   ```
4. Note that the `applications` documentation covers both Community and Enterprise features; Enterprise-only features may not be available in Odoo Community Edition.

## Output

The correct documentation URL or local path for the requested Odoo version and topic.
