# Contributing, testing, and benchmarking

## Tests

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```

CI runs tests on Linux and macOS, using Julia 1.10 and the current stable
release. Benchmark dependencies live in a separate Julia project.

## Run local benchmarks with one command

```sh
julia --startup-file=no benchmark/bench.jl
```

The first run installs Julia benchmark dependencies. Quick mode limits array
sizes and time per case. To run the complete suite:

```sh
julia --startup-file=no benchmark/bench.jl --full
```

To choose a different output directory:

```sh
julia --startup-file=no benchmark/bench.jl --out /tmp/goose-bench
```

There are two benchmark suites: `run.jl` (basic operations) and `staged.jl`
(multiple operands and BLAS). They run in **two separate Julia processes** to
avoid constant and method collisions. CSV results contain minimum, median,
p95, and GC allocations; the basic suite also reports arena usage.

## Benchmark a GitHub pull request

There are two options:

- Add the `benchmark` label to the PR (the workflow runs when the label is added).
- From a terminal with authenticated `gh`, run a single command:

```sh
gh workflow run benchmark.yml --ref main -f pr=123
```

Replace `123` with the pull request number. CSV results and environment
information are saved as a **downloadable artifact** in the GitHub Actions run.
This workflow has read-only repository access and does not expose secrets to PR
changes. It does not automatically compare performance across machines, since
shared runners cannot guarantee stable microbenchmark timings.

## Build and publish documentation

```sh
julia --project=docs -e 'using Pkg; Pkg.develop(path=pwd()); Pkg.instantiate()'
julia --project=docs docs/make.jl
```

CI builds the docs on PRs and publishes `docs/build` to GitHub Pages after
pushes to `main`. Under GitHub repository settings, select
**Settings → Pages → Build and deployment → Source: GitHub Actions**.
