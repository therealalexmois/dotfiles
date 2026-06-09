# API-change review (light)

Load this when the diff changes a public interface: function/class signatures, return types, error contracts, request/response schemas, HTTP endpoints, or event payloads. This is a fast checklist. For a full REST API design audit, breaking-change detection, and a design scorecard, defer to the standalone `api-design-reviewer` skill.

## Fast checklist

- Backward compatibility: does an existing caller break? If a breaking change is intended, is it documented and decided, not accidental?
- Naming: does the new surface match the domain and the existing API conventions?
- Input/output semantics: are types, nullability, units, and error shapes consistent with neighbors?
- Versioning: if the contract breaks, is versioning or a migration path handled?
- Error contract: are error types and the user-facing part of error messages stable where callers depend on them?
- Observability and operational impact: does the change alter logs, metrics, or operational behavior that consumers rely on?

## When to escalate to api-design-reviewer

Hand off to `api-design-reviewer` when the change adds or reshapes multiple endpoints, introduces a new public API surface, or is part of a v2 migration. Note the handoff as a finding rather than attempting a full design review here.
