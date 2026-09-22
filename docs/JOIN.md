# Joining the wire-bridge (federation over gitbroker)

Two sandboxed `8`s federate here with **outbound-only** GitHub access — no inbound
reachability, no tunnel, no shared network. Everything is one wire atom: **CALL**
(`http_request`), stored-and-forwarded as git commits.

## Roles
- **HOST** (exposes its 8): runs a `gitbroker` poller against its own witness with its own
  **policy** (host-side, OUTSIDE this checkout). It fires allowed envelopes and commits
  receipts. Run ONE host per direction (see addressing).
- **FAR END** (observes/drives the host): writes `commands/<ulid>.json` envelopes and pulls
  `receipts/<ulid>.json`. No poller, no witness needed.

## Prereqs
- The `gitbroker` binary from `adapters` (`./build.sh` → `.bin/gitbroker`).
- Push access to this repo (a GitHub token/SSH key with push to `rrrishi123/wire-bridge`).

## As HOST — let the other side observe YOUR 8
1. Clone: `git clone <this repo> ~/wire-bridge`
2. Write a policy OUTSIDE the clone, e.g. `~/wire-bridge-policy.json`:
   ```json
   { "allow_methods": ["GET"],
     "allow_url_prefixes": ["http://127.0.0.1:<your-collector-port>/"],
     "egress": { "body": true, "headers": true } }
   ```
   (To expose a container desktop, add its CDP/screenshot URL prefix.)
3. Run the poller:
   ```
   gitbroker -bridge ~/wire-bridge -policy ~/wire-bridge-policy.json \
     -collector http://127.0.0.1:<your-collector-port> -actor <your-name> -interval 10s
   ```
   Missing policy = CLOSED. Policy/slots inside the clone = refuses to start (G1/G2).

## As FAR END — observe/drive the other 8
Write an envelope and push:
```json
{ "schema":"gitbroker/envelope/v1", "ulid":"<26-char ULID>", "seq":1, "atom":"call",
  "agent":"me", "why":"read peer nodes",
  "call": { "method":"GET", "url":"http://127.0.0.1:7070/nodes" } }
```
`git add commands/<ulid>.json && git commit -m propose && git push`. Pull for the receipt.
The host's policy decides; a refused envelope gets a receipt saying so. `state/halt`
(any content) freezes all firing until removed.

## Addressing caveat (read this)
Routing is by the CALL's **URL prefix**, matched against each host's policy. Two hosts on
the same loopback (`127.0.0.1:7070`) both match the same envelope → whoever commits the
receipt first wins (idempotent by receipt existence), the other skips. So for a clean demo,
run **one host per direction**: to observe A, only A runs a poller. A `site`/target field
in the envelope is the planned fix for simultaneous bidirectional hosts.

## Safety
Nothing secret lives in this repo. Policy + auth-slots are host-side. Receipts carry only
allowlisted headers (Content-Type, Content-Length, X-8-*) + a body digest; an
auth-slot call publishes only the digest unless the policy opts in. URLs with userinfo or
`?access_key=`/token/sig are refused structurally (internal/guard, #1145).
