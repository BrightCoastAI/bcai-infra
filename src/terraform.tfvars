organization_id    = "374671535671"
billing_account_id = "01BC15-C2F86C-76D45B"

# Extra owners for the CI/Buildkite project
ci_additional_admins = [
  "user:core@brightcoast.ai",
  "user:ben@brightcoast.ai",
]

# Buildkite organization slug from https://buildkite.com/<org-slug>
buildkite_organization_slug = "bencoastai"

# Source project for the existing Buildkite agent token secret ("buildkite-agent").
buildkite_source_secret_project_id = "bc-prod-brightcoast"

# The secret name in the source project (overriding default "buildkite-agent-token")
buildkite_source_agent_secret_name = "buildkite-token"
