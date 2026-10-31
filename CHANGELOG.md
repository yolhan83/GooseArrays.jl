# Changelog

## 0.1.1 — 2026-10-31

Correctif de compatibilité Linux/Julia 1.10 : `mul!` applique explicitement
`alpha == 0` sans lire les opérandes (y compris dans le chemin BLAS), et
les tests d'allocations forcent la spécialisation de leur mesure variadique.
La couverture des valeurs `NaN` et des facteurs d'échelle est renforcée.

## 0.1.0 — 2026-10-31

Première version publique. Elle reprend l'implémentation finale du prototype :
`DataStack`, `GooseArray` (forme dynamique), `StaticGooseArray` (forme statique),
portées et invalidation, `map`/`mapreduce` multi-entrées, broadcast et extension
`LinearAlgebra`.

Les résultats de performance du prototype (anciennement numéroté en interne
`0.6.0`) sont archivés en tant que référence initiale. Les anciennes itérations
et les scripts de comparaison entre versions ne font pas partie de cette release.
