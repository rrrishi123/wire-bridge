# wire-bridge

Store-and-forward **CALL** bridge for the four-system `gitbroker` relay. Two sandboxed
`8`s that can each reach GitHub (outbound only) federate through this repo without any
inbound reachability, tunnel, or shared network.

## Shape (2 atoms, 1 transport)
- **Far end PROPOSES**: writes `commands/<ulid>.json` — an envelope carrying exactly one
  `http_request` (the wire's CALL atom) — and pushes.
- **Host DECIDES + fires**: a `gitbroker` poller pulls, checks its **policy** (host-side,
  lives OUTSIDE this checkout), fires the CALL through its **8 witness** (stamps
  `X-8-Witness`), and commits `receipts/<ulid>.json` back.
- **Revocation**: `state/halt` — if present, the host leaves envelopes unfired until lifted.

## Safety (nothing secret lives here)
Policy and auth-slots are host-side and never enter this repo. Receipts carry only
allowlisted headers + a body digest. This repo is public precisely because it holds no
secret — authority is the host's policy, not access to the bridge. See
`adapters/gitbroker` (#1133, security #1145).

## Addressing
Each side runs its own poller against its own witness with its own policy. An envelope's
target names which side should fire it (by the CALL's URL / a `site` tag the policy gates).
