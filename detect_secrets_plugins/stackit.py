import re
from detect_secrets.plugins.base import RegexBasedDetector


class StackitProjectIdDetector(RegexBasedDetector):
    """Detects STACKIT project IDs (UUID assigned to STACKIT_PROJECT_ID)."""

    name = "StackitProjectIdDetector"
    secret_type = "STACKIT Project ID"  # pragma: allowlist secret

    denylist = [
        re.compile(
            r'(?i)stackit_project_id\s*[=:]\s*["\']?'
            r'([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})'
            r'["\']?'
        ),
    ]


class StackitServiceAccountKeyDetector(RegexBasedDetector):
    """Detects STACKIT service account keys (JSON with privateKey field)."""

    name = "StackitServiceAccountKeyDetector"
    secret_type = "STACKIT Service Account Key"  # pragma: allowlist secret

    denylist = [
        re.compile(r'"privateKey"\s*:\s*"-----BEGIN [A-Z ]*KEY-----'),  # pragma: allowlist secret
        re.compile(r'"projectId"\s*:\s*"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"'),  # pragma: allowlist secret
    ]
