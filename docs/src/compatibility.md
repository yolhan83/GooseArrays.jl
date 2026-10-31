# Couverture par rapport à FixedSizeArrays.jl

Le but est de fournir une interface de tableau Julia étendue avec stockage en
arène. Ce n'est pas une compatibilité de chaque constructeur ou extension du
package d'origine : un propriétaire mémoire explicite reste nécessaire.

| Fonctionnalité | GooseArrays 0.1 |
| --- | --- |
| Taille fixe, éléments modifiables, rang quelconque | Oui, rang 0 inclus |
| Longueurs dynamiques absentes du type | Oui pour GooseArray ; formes dans le type pour StaticGooseArray |
| Constructeurs `undef`, tuples et dimensions séparées | Oui, avec arène explicite |
| Copie et conversion d'un `AbstractArray` | Oui, indices commençant à 1 |
| Alias vecteur / matrice | Oui |
| Indexation linéaire / cartésienne / tranches / masques | Interface générique Julia |
| `size`, `length`, `axes`, `strides`, `elsize`, `isassigned` | Oui |
| Itération, destructuration, réductions, `map` | Oui ; map unaire conserve les formes statiques |
| map! unaire ou multi-entrées entre tableaux Goose | Chemin indexé ; longueur minimale, alias et conversions comme Base |
| map à plusieurs entrées Goose | Résultat typé dans la première arène ; statique si toutes les entrées le sont, repli Base pour les types inconnus |
| mapreduce à plusieurs entrées Goose | Global + numérique natif sans résultat intermédiaire ; dims/op/init personnalisés par repli |
| mul!(y,A,x), axpy!, axpby! | Noyaux natifs réels courts, BLAS au-delà et repli pour les autres scalaires |
| `similar`, `copy`, `copy!`, `copyto!` | Oui, sans redimensionnement |
| Broadcast en place et hors place, fusion | Oui ; résultat dans une arène Goose |
| Broadcast de rang 0 | Renvoie un scalaire comme Base |
| `reshape`, dimensions inférées `:`, `vec`, vues | Oui, partage du stockage |
| Pointeurs, appels C et BLAS, `mul!`, `dot` | Oui ; limites de durée de vie des pointeurs bruts |
| `rand!` | Fonctionnement générique, sans dépendance au package Random |
| Objets contenant des références GC | Refusés ; stockage brut non tracé |
| `Union` isbits, types de taille zéro | Refusés dans cette version |
| Dimensions statiques explicites | StaticGooseArray via alias ou Val(tuple) ; pas de dépendance Static.jl |
| Produits de matrices / vecteurs statiques | Extension optionnelle LinearAlgebra ; forme du résultat conservée |
| Conversions entre formes statiques et dynamiques | Partage du stockage, sans copie, avec durée de vie d'origine |
| Backend `Vector` / `Memory` configurable | Remplacé par le mapping de DataStack |
| `similar(Type, dims)` sans propriétaire | Pas d'arène implicite globale |
| `wrap` d'un `Vector` existant sans copie | Exclu : le stockage doit appartenir à l'arène |
| `collect_as`, extensions StaticArrayInterface | Pas de dépendances ni d'extensions dédiées |
| Adapt, GPU, MPI | Pas d'extensions dédiées ni de validation de compatibilité |
| `push!`, `resize!` | Exclus, comme attendu pour une taille fixe |

La couverture explicitement testée est dans `test/runtests.jl` ; l'héritage des
algorithmes génériques ne constitue pas une validation de tous les packages de
l'écosystème. Le CI fourni permet d'élargir la validation à macOS/Linux et aux
versions Julia prises en charge. Il n'a pas été exécuté à distance dans cette livraison.
