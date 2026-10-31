# Contribuer, tester et mesurer

## Tests

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```

La CI exécute les tests sur Linux et macOS, pour Julia 1.10 et la branche
stable courante. Les dépendances des benchmarks vivent dans un projet séparé.

## Benchmark local en une commande

```sh
julia --startup-file=no benchmark/bench.jl
```

Le premier lancement installe les dépendances Julia du banc. Le mode rapide
limite les tailles et le temps par cas. Pour le banc complet :

```sh
julia --startup-file=no benchmark/bench.jl --full
```

Pour choisir le dossier de sortie :

```sh
julia --startup-file=no benchmark/bench.jl --out /tmp/goose-bench
```

Le benchmark comporte deux campagnes : `run.jl` (opérations de base) et
`staged.jl` (multi-entrées et BLAS). Elles sont lancées dans **deux processus
Julia distincts**, pour éviter les collisions de constantes et de méthodes.
Les CSV contiennent temps minimal, médian, p95, allocations GC et, pour le
premier banc, consommation d'arène.

## Benchmark d'une pull request GitHub

Deux possibilités :

- Dans la PR, ajouter le label `benchmark` (workflow déclenché à l'ajout du label).
- Depuis ton terminal, avec `gh` authentifié, lancer une seule commande :

```sh
gh workflow run benchmark.yml --ref main -f pr=123
```

Remplacer `123` par le numéro de PR. Les résultats CSV et les informations
d'environnement sont déposés en **artefact téléchargeable** dans le run GitHub
Actions. Ce workflow ne détient que le droit de lecture du dépôt et n'expose
aucune clé aux changements de la PR. Il ne compare pas automatiquement les temps
à une autre machine, puisque les runners partagés ne garantissent pas la stabilité
microbenchmark.

## Documentation locale et publication

```sh
julia --project=docs -e 'using Pkg; Pkg.develop(path=pwd()); Pkg.instantiate()'
julia --project=docs docs/make.jl
```

La CI construit la documentation sur les PR et publie `docs/build` sur
GitHub Pages seulement après un push sur `main`. Dans le dépôt GitHub,
configurer **Settings → Pages → Build and deployment → Source: GitHub Actions**.
