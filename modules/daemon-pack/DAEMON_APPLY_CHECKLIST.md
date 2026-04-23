# Daemon Apply Checklist

Before enabling any daemon from this pack, verify each item.

## Required for All Daemons

- [ ] Daemon has a clear, easy stop mechanism (process kill or stop script).
- [ ] Daemon writes readable logs to a known local path.
- [ ] Daemon does not require elevated privileges.
- [ ] Daemon behavior is fully described before starting.
- [ ] No hidden persistence mechanism (no auto-restart on login unless explicitly asked for).

## Required for Local Daemons

- [ ] No external network connections.
- [ ] All file writes are inside the project or a specified local path.
- [ ] Output is visible and auditable.

## Required for Supervised Daemons

- [ ] External destination is reviewed and trusted.
- [ ] Data sent externally is classified as non-sensitive or approved.
- [ ] Ahmed has approved the external connection explicitly.
- [ ] Stop and restart behavior is tested before deploying.

## After Enabling

- [ ] Verify daemon is running with expected behavior.
- [ ] Verify logs are being written as expected.
- [ ] Verify stop mechanism works correctly.
- [ ] Add daemon to local session notes or status summary if long-lived.
