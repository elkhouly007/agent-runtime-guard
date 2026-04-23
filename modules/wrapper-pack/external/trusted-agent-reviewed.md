# trusted-agent-reviewed

## Class

external

## Purpose

Wrap trusted external agent delegation with reviewed payload and visible intent.

## Allowed Use

- reviewed non-sensitive prompt routing;
- controlled delegation to known harnesses;
- visible reporting of the target agent or harness.

## Approval Boundary

Ask before sending personal or confidential data, performing deletion, or triggering other high-risk actions through the delegated flow.

## Rejection Cases

Reject use if the wrapper hides the destination, obscures the payload, or claims approval that did not happen.
