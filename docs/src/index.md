# GooseArrays.jl

GooseArrays.jl reprend l'idée de tableaux temporaires à durée de vie contrôlée,
dans l'esprit de **Goose**, et l'intègre à l'interface `AbstractArray` de Julia.
Les éléments sont stockés dans une **arène mmap** préallouée, sans allocation GC
pour chaque tampon : les formes peuvent être dynamiques (`GooseArray`) ou figées
dans les types (`StaticGooseArray`). Un tableau devient invalide lorsqu'on quitte
sa portée ou lorsque l'arène est réinitialisée ou fermée.

!!! warning "Ce n'est pas la pile native"
    Le nom `DataStack` décrit une discipline d'allocation et de durée de vie.
    Ni les données ni les descripteurs ne sont garantis sur la stack native.
    Les tableaux peuvent allouer un descripteur sur le heap s'ils s'échappent.

Pour démarrer, voir [Démarrage](guide.md), puis [API](api.md).
Les conditions de mesures sont dans [Performances](performance.md).

## Fonctionnement en bref

- Une arène est créée avec `DataStack` ou `with_datastack`.
- `alloc!` ou les constructeurs `GooseArray`/`StaticGooseArray` placent des données
  contiguës dans cette arène, sans redimensionnement ultérieur.
- `with_scope` réserve une portée temporaire et restaure le curseur à la sortie.
- `reset!` et `close` invalident les tableaux concernés ; les accès invalides lèvent
  `InvalidatedArrayError`, y compris sous `@inbounds`.
- Une arène est propre à la `Task` qui l'a créée ; elle ne se partage pas entre tâches.

Seuls les éléments `isbits` de taille strictement positive sont acceptés.
Backends actuellement pris en charge : Linux, macOS et FreeBSD.
