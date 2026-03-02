# Comments Load Tests

This folder contains API load tests for hot community/update comment threads.

## Prerequisites

1. Install k6 locally: https://k6.io/docs/get-started/installation/
2. Start backend API.
3. Provide a valid bearer token and thread ids.

## Run

```bash
cd backend
BASE_URL=http://localhost:3080/api \
AUTH_TOKEN=<bearer-token> \
UPDATE_IDS=<update-id-1>,<update-id-2> \
COMMUNITY_POST_IDS=<post-id-1>,<post-id-2> \
bun run loadtest:comments
```

## What It Simulates

1. Reader scenario ramps to 1000 concurrent virtual users reading comment threads.
2. Writer scenario posts comments concurrently to create realistic write pressure.
3. Thresholds track failure rate and p95/p99 latency.

## Notes

1. Use dedicated test ids and a disposable environment for write load runs.
2. The script targets API throughput and latency, not mobile rendering performance.
