# Project Constitution

> This constitution defines the core principles and governance rules for this project.
> It is used by the `/do-the-thing` workflow to ensure all development aligns with project standards.

---

## Core Principles

### I. Spec-First Development
All features must be specified before implementation begins. Specifications define the "what" and "why", while plans define the "how".

**Compliance**: Every feature must have a corresponding `spec.md` before any code is written.

### II. Test-Driven Quality
Tests validate that implementations match specifications. All critical paths must be covered.

**Compliance**: Minimum 80% code coverage for core functionality. All user stories must have corresponding tests.

### III. Constitution Alignment
All development work must align with the principles defined in this constitution. The workflow gates check for compliance.

**Compliance**: Phase 6 (Analysis) verifies constitution alignment. Violations must be remediated in Phase 7.

### IV. Iterative Refinement
Development proceeds in phases with clear checkpoints. Each phase builds on the previous, with opportunities for clarification.

**Compliance**: No phase can be skipped. Clarification (Phase 3) is mandatory when ambiguities exist.

### V. Documentation as Code
Documentation is maintained alongside code and is part of the deliverable. Specifications, plans, and task lists are living documents.

**Compliance**: All specs/, plans/, and tasks/ must be updated to reflect actual implementation.

---

## Governance

### Amendment Process
Changes to this constitution require:
1. Explicit discussion with stakeholders
2. Version increment (MAJOR.MINOR.PATCH)
3. Documentation of rationale for change

### Compliance Review
All specs, plans, and implementations must pass constitution check gates:
- Phase 1: Constitution loaded and parsed
- Phase 6: Constitution alignment verified
- Phase 7: Constitution violations remediated
- Phase 9: Constitution updated with new capabilities

### Version History
| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | [RATIFICATION_DATE] | Initial constitution |

---

**Version**: 1.0.0 | **Ratified**: [RATIFICATION_DATE] | **Last Amended**: [RATIFICATION_DATE]

> [!TIP]
> Customize this constitution for your project by:
> 1. Updating the principles to match your project's needs
> 2. Adding project-specific compliance requirements
> 3. Setting the ratification date when you finalize

