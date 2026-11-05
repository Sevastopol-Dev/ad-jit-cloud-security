#!/usr/bin/env python3
"""
JitElevation.py - Zero-Dependency Ephemeral JIT Elevation Orchestrator
Enforces Zero Standing Privileges (ZSP) via automated AD group mutation and TTL rollback.
"""

import argparse
import logging
import platform
import subprocess
import sys
import time

# Configure clean logging for audit trails
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s]: %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)
logger = logging.getLogger("JitEngine")


def modify_ad_group(username: str, group: str, action: str) -> bool:
    """Mutates group membership. Adapts between Windows net commands and Linux mocks for local testing."""
    current_os = platform.system()

    if current_os == "Windows":
        cmd = [
            "net",
            "group",
            group,
            username,
            "/add" if action == "add" else "/delete",
        ]
    else:
        # Cross-platform fallback/mock for Linux local development environments
        logger.warning(
            f"[OS: {current_os}] Windows 'net' utility not available. Simulating AD mutation for '{username}' -> '{group}' ({action})."
        )
        return True  # Simulate success for local Linux testing

    try:
        subprocess.run(cmd, capture_output=True, text=True, check=True)
        logger.info(f"SUCCESS: {action.upper()} user '{username}' -> group '{group}'")
        return True
    except subprocess.CalledProcessError as e:
        logger.error(f"FAIL: AD mutation error -> {e.stderr.strip()}")
        return False


def run_jit_session(username: str, group: str, duration_mins: int, justification: str):
    """Manages the JIT session lifecycle with guaranteed cleanup logic."""
    logger.info(
        f"Starting JIT Session for '{username}' on '{group}' ({duration_mins} mins)"
    )
    logger.info(f"Audit Justification: '{justification}'")

    granted = False
    try:
        # Step 1: Grant temporary privileges
        granted = modify_ad_group(username, group, "add")
        if not granted:
            logger.critical("Aborting: Could not establish elevation.")
            return

        # Step 2: Active countdown timer
        total_seconds = duration_mins * 60
        elapsed = 0
        while elapsed < total_seconds:
            time.sleep(10)
            elapsed += 10
            if elapsed % 300 == 0:  # Heartbeat every 5 mins
                logger.info(
                    f"Session active. Remaining: {(total_seconds - elapsed) // 60}m"
                )

    except KeyboardInterrupt:
        logger.warning("Manual override detected. Forcing immediate cleanup...")

    finally:
        # Step 3: Guaranteed Safety Net (Executes on exit, crash, or completion)
        if granted:
            logger.info("Reclaiming privileges... Restoring baseline.")
            if modify_ad_group(username, group, "remove"):
                logger.info("REVOCATION COMPLETE: Zero standing privileges restored.")
            else:
                logger.critical(
                    "CRITICAL: Manual intervention required to remove group membership!"
                )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="JIT Privilege Elevation Daemon")
    parser.add_argument("--user", required=True, help="Target username")
    parser.add_argument(
        "--group", required=True, help="Privileged Active Directory group"
    )
    parser.add_argument(
        "--duration", type=int, default=15, help="TTL in minutes (Max: 60)"
    )
    parser.add_argument(
        "--justification", required=True, help="Change management reason"
    )

    args = parser.parse_args()

    if args.duration > 60:
        logger.error("Policy violation: Maximum JIT duration is 60 minutes.")
        sys.exit(1)

    run_jit_session(args.user, args.group, args.duration, args.justification)
