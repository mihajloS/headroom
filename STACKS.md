# Stack flags

Flags that cap a tool's own parallelism. `N` is 1 at **low** and half the cores at **medium**; at **high** use the tool's defaults. At low, prefix the whole command with `nice -n 19`.

## Node / TypeScript

| Tool | Cap workers | Notes |
| --- | --- | --- |
| jest | `--maxWorkers=N` (`--runInBand` at low) | run one file: `jest path/to/file.test.ts` |
| vitest | `--maxWorkers=N` (`--no-file-parallelism` at low) | `vitest run path/to/file` — `run` avoids watch mode |
| tsc | `tsc --noEmit -p <project>` once | `--watch` keeps a process alive |
| vite / webpack / next build | `NODE_OPTIONS=--max-old-space-size=<MB>` | at low set MB to about half of available RAM |
| yarn (v1) | `yarn install --frozen-lockfile --prefer-offline --network-concurrency 1` | |
| yarn (berry) | `yarn install --immutable` | |
| npm | `npm ci --prefer-offline` | |
| pnpm | `pnpm install --frozen-lockfile --prefer-offline --child-concurrency=N` | |

## Python

| Tool | Cap workers | Notes |
| --- | --- | --- |
| pytest | drop `-n` / `-n auto` (pytest-xdist) at low; `-n N` at medium | one file: `pytest tests/test_x.py`, one test: `-k name` |
| poetry | `poetry install --no-root --sync` only when `poetry.lock` changed | |
| pip | `pip install -r requirements.txt` only when the file changed | |
| uvicorn / gunicorn | `--workers 1`, no `--reload` unless it is the task | |

## Native builds

| Tool | Cap workers |
| --- | --- |
| make | `make -jN` |
| cargo | `cargo build -j N`; test one crate with `-p <crate>` |
| go | `GOMAXPROCS=N go test ./pkg/...` scoped to the changed package |
| gradle | `--max-workers=N --no-daemon` |

## Containers and browsers

- docker build: one image at a time; at low, build images in CI or on a stronger machine and pull the result.
- docker compose: start only the service the task needs (`docker compose up -d <service>`), stop it when done.
- Playwright / Puppeteer: one browser, `--workers=N`, headless, closed after the check.
