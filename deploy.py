#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "rich>=14.2.0",
# ]
# ///

"""Interactive OpenTofu deployment helper."""

from __future__ import annotations

import argparse
import os
import re
import shlex
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Iterable, List, Optional

from rich import box
from rich.console import Console
from rich.panel import Panel
from rich.prompt import Confirm
from rich.table import Table
from rich.text import Text
from rich.traceback import install as install_rich_traceback


install_rich_traceback(show_locals=True)
console = Console()

REQUIRED_OPENTOFU_VERSION = "1.6.0"


def parse_args() -> tuple[argparse.Namespace, List[str]]:
    parser = argparse.ArgumentParser(
        description="Run tofu init/plan/apply with a friendly CLI wrapper.",
        allow_abbrev=False,
    )
    parser.add_argument(
        "--plan-only",
        action="store_true",
        help="Run tofu plan and stop without applying changes.",
    )
    parser.add_argument(
        "-auto-approve",
        "--auto-approve",
        dest="auto_approve",
        action="store_true",
        help="Skip the confirmation prompt and auto-approve apply.",
    )
    parser.add_argument(
        "--tofu-bin",
        default=os.environ.get("TOFU_BIN", os.environ.get("TERRAFORM_BIN", "tofu")),
        help="Path to the tofu binary (defaults to TOFU_BIN/TERRAFORM_BIN or tofu on PATH).",
    )
    parser.add_argument(
        "--tf-dir",
        default=None,
        help="Override the OpenTofu working directory (defaults to ./src relative to this script).",
    )

    args, passthrough = parser.parse_known_args()
    return args, passthrough


def console_rule(title: str, style: str = "green") -> None:
    console.rule(Text(title, style=f"bold {style}"))


def read_quota_project(tf_vars_path: Path) -> Optional[str]:
    if not tf_vars_path.exists():
        return None

    quota_pattern = re.compile(r'^\s*quota_project_id\s*=\s*"([^"]+)"')
    for line in tf_vars_path.read_text().splitlines():
        match = quota_pattern.match(line)
        if match:
            return match.group(1)
    return None


def compare_versions(lhs: str, rhs: str) -> int:
    """
    Return -1 when lhs < rhs, 0 when equal, 1 when lhs > rhs.
    """

    def tokenize(version: str) -> List[int]:
        return [int(part) for part in re.split(r"[.+-]", version) if part.isdigit()]

    left_parts = tokenize(lhs)
    right_parts = tokenize(rhs)
    max_len = max(len(left_parts), len(right_parts))
    left_parts.extend([0] * (max_len - len(left_parts)))
    right_parts.extend([0] * (max_len - len(right_parts)))
    for left, right in zip(left_parts, right_parts, strict=False):
        if left < right:
            return -1
        if left > right:
            return 1
    return 0


def ensure_opentofu_version(tofu_bin: str) -> str:
    version_cmd = [tofu_bin, "version"]
    try:
        completed = subprocess.run(
            version_cmd,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
    except (OSError, subprocess.CalledProcessError) as exc:  # pragma: no cover - user env issue
        raise SystemExit(f"Unable to execute {' '.join(version_cmd)}: {exc}") from exc

    first_line = completed.stdout.splitlines()[0] if completed.stdout else ""
    match = re.search(r"OpenTofu v?([\d.]+)", first_line)
    version = match.group(1) if match else ""
    if not version:
        raise SystemExit(f"Could not parse OpenTofu version from output:\n{completed.stdout}")

    console.print(f"[bold cyan]OpenTofu version detected:[/] {version}")
    if compare_versions(version, REQUIRED_OPENTOFU_VERSION) < 0:
        instructions = (
            "- macOS (Homebrew): [italic]brew install opentofu[/]\n"
            "- Linux/Other: https://opentofu.org/docs/intro/install/"
        ).format(ver=REQUIRED_OPENTOFU_VERSION)
        raise SystemExit(
            f"OpenTofu {REQUIRED_OPENTOFU_VERSION}+ is required, but found {version}.\n\n"
            f"{instructions}\n\n"
            "You can also set TOFU_BIN to point at an alternate binary and re-run."
        )
    return version


def describe_environment(tofu_bin: str, tf_dir: Path, quota_project: Optional[str]) -> None:
    table = Table.grid(padding=(0, 1), expand=True)
    table.add_column(justify="right", style="bold green", no_wrap=True)
    table.add_column()
    table.add_row("OpenTofu binary:", f"[white]{tofu_bin}[/]")
    table.add_row("Working directory:", f"[white]{tf_dir}[/]")
    table.add_row("Quota project:", f"[white]{quota_project or '(not set)'}[/]")
    console.print(Panel(table, title="Deployment Context", box=box.ROUNDED))


def stream_command(
    command: Iterable[str],
    *,
    env: Optional[dict[str, str]] = None,
    title: str,
) -> str:
    """Stream command output and return captured output for error analysis."""
    command_list = list(command)
    console_rule(title)
    console.print(f"[cyan]$ {shlex.join(command_list)}[/]")
    process = subprocess.Popen(
        command_list,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        env=env,
    )

    assert process.stdout is not None
    output_lines = []
    for line in process.stdout:
        console.print(line.rstrip())
        output_lines.append(line)

    return_code = process.wait()
    full_output = "".join(output_lines)
    if return_code != 0:
        error = subprocess.CalledProcessError(return_code, command_list)
        error.output = full_output
        raise error
    return full_output


def main() -> None:
    args, passthrough = parse_args()

    tofu_bin = args.tofu_bin
    if shutil.which(tofu_bin) is None:
        raise SystemExit(
            f"OpenTofu binary '{tofu_bin}' not found. " "Install OpenTofu or set TOFU_BIN to the desired path."
        )

    script_dir = Path(__file__).resolve().parent
    tf_dir = Path(args.tf_dir) if args.tf_dir else script_dir / "src"
    tf_vars_file = tf_dir / "terraform.tfvars"

    console.print(f"[bold]Using OpenTofu binary:[/] {tofu_bin}")
    console.print(f"[bold]OpenTofu working directory:[/] {tf_dir}")
    opentofu_version = ensure_opentofu_version(tofu_bin)

    env = os.environ.copy()
    quota_project = env.get("GOOGLE_CLOUD_QUOTA_PROJECT")
    if not quota_project:
        quota_project = read_quota_project(tf_vars_file)
        if quota_project:
            env["GOOGLE_CLOUD_QUOTA_PROJECT"] = quota_project
            console.print(f"[bold]Using quota project from terraform.tfvars:[/] {quota_project}")
        else:
            console.print("[yellow]Warning: GOOGLE_CLOUD_QUOTA_PROJECT is not set; falling back to ADC defaults.[/]")
    else:
        console.print(f"[bold]Using quota project from environment:[/] {quota_project}")

    describe_environment(tofu_bin, tf_dir, quota_project)

    tf_common_args = [f"-chdir={tf_dir}", "-input=false"]
    init_cmd = [tofu_bin, *tf_common_args[:1], "init", *tf_common_args[1:]]
    plan_cmd = [tofu_bin, *tf_common_args[:1], "plan", *tf_common_args[1:], *passthrough]
    apply_cmd = [
        tofu_bin,
        *tf_common_args[:1],
        "apply",
        *tf_common_args[1:],
        "-auto-approve",
        *passthrough,
    ]

    try:
        stream_command(init_cmd, env=env, title="Initializing OpenTofu")
        stream_command(plan_cmd, env=env, title="Generating OpenTofu Plan")
    except subprocess.CalledProcessError as exc:
        # Check for common authentication errors and provide helpful guidance
        error_output = ""
        if hasattr(exc, "output") and exc.output:
            error_output = str(exc.output).lower()

        help_text = f"Command failed with exit code {exc.returncode}:\n[dim]{shlex.join(exc.cmd)}[/]"

        # Detect authentication errors
        if "could not find default credentials" in error_output or "authentication" in error_output:
            help_text += "\n\n[yellow]Authentication Issue Detected[/yellow]\n"
            help_text += "\nYou need to authenticate with Google Cloud using an account with appropriate permissions.\n"
            help_text += "Run these commands:\n\n"
            help_text += "[cyan]gcloud auth login[/cyan]\n"
            help_text += "[cyan]gcloud auth application-default login[/cyan]\n"
            help_text += "\nIf you continue to see errors, you may also need to set:\n"
            help_text += "[cyan]export GOOGLE_CLOUD_QUOTA_PROJECT=bc-prod-brightcoast[/cyan]"
        elif "permission" in error_output or "forbidden" in error_output:
            help_text += "\n\n[yellow]Permission Issue Detected[/yellow]\n"
            help_text += "\nYour account may lack required permissions. Verify:\n"
            help_text += "- You have access to the GCS state bucket (gs://bc-prod-brightcoast-tfstate)\n"
            help_text += "- You have organization-level permissions to create projects\n"
            help_text += "- You are a billing administrator on the Brightcoast billing account"
        elif "bucket" in error_output and "not found" in error_output:
            help_text += "\n\n[yellow]State Bucket Issue Detected[/yellow]\n"
            help_text += "\nThe remote state bucket may not exist or you lack access.\n"
            help_text += "Verify the bucket exists: [cyan]gcloud storage ls gs://bc-prod-brightcoast-tfstate/[/cyan]"

        console.print(
            Panel(
                help_text,
                title="OpenTofu command failed",
                border_style="red",
            )
        )
        raise SystemExit(exc.returncode) from exc

    if args.plan_only:
        console_rule("Plan Complete", style="cyan")
        console.print(
            Panel.fit(
                "Plan finished successfully. Re-run without --plan-only to apply changes.",
                border_style="cyan",
            )
        )
        return

    if not args.auto_approve:
        if not Confirm.ask("Apply this plan?", default=False, console=console, show_choices=True):
            console.print("[yellow]Aborting without applying changes.[/]")
            return

    try:
        stream_command(apply_cmd, env=env, title="Applying OpenTofu Changes")
    except subprocess.CalledProcessError as exc:
        console.print(
            Panel(
                f"OpenTofu apply failed with exit code {exc.returncode}:\n[dim]{shlex.join(exc.cmd)}[/]",
                title="Apply Failed",
                border_style="red",
            )
        )
        raise SystemExit(exc.returncode) from exc

    console_rule("Done", style="green")
    console.print(
        Panel.fit(
            f"OpenTofu apply completed successfully with {opentofu_version}.",
            border_style="green",
        )
    )


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:  # pragma: no cover - user ctrl+c
        console.print("\n[red]Deployment interrupted by user.[/]")
        sys.exit(130)
