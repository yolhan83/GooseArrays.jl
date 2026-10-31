# Référence API

## Allocation et arène

```@docs
DataStack
with_datastack
with_scope
alloc!
reset!
```

## Types de tableaux

```@docs
GooseArray
```

`GooseVector`, `GooseMatrix`, `StaticGooseVector` et `StaticGooseMatrix`
sont des alias pratiques pour les dimensions 1 et 2. `AbstractGooseArray`
rassemble les deux familles.

## Erreurs et introspection

```@docs
InvalidatedArrayError
```

`bytesused(s)` renvoie le nombre d'octets consommés dans l'arène,
`capacity(s)` sa taille réservée, `available(s)` le nombre d'octets disponibles.
`close(s)` ferme le mapping et invalide les descripteurs.

Les méthodes usuelles de `Base` et `LinearAlgebra` sont expliquées dans
[Démarrage](guide.md) et [Compatibilité](compatibility.md).
