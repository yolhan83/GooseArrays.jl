# Architecture

## Représentation

`DataStack` est un objet mutable créé une fois. Il possède le mapping anonyme,
son curseur en octets, sa capacité, la tâche propriétaire, le niveau actif et un
vecteur d'objets `_ScopeState` préalloués. Ce vecteur contient uniquement les métadonnées
des portées, jamais les données des tableaux. La pile utilise un niveau racine
et au plus `max_scopes` niveaux imbriqués.

`GooseArray{T,N}` est un descripteur immutable : référence au propriétaire,
`Ptr{T}`, `NTuple{N,Int}` de dimensions, longueur, référence à `_ScopeState` et génération.
La taille et les adresses sont des champs, pas des paramètres de type.
La référence au propriétaire empêche une finalisation prématurée. Elle empêche
aussi de garantir que tout descripteur échappant sera alloué sans GC.

`StaticGooseArray{T,N,S}` garde seulement le propriétaire, le pointeur, l'état de
portée et la génération. S est un type tuple tel que Tuple{2,3}, sans champ de
dimensions ou de longueur. Le descripteur mesure ici 32 octets, contre 48 pour
GooseVector{Float64}. Les deux sous-typent AbstractGooseArray{T,N}, lui-même dense,
et partagent leurs méthodes d'accès et de sécurité. Le type statique n'est pas
isbits et son stockage reste mmap. Chaque forme peut spécialiser les consommateurs.

Les formes explicites sont validées avant allocation. Les copies et similar sans
nouvelles dimensions conservent S ; les dimensions ordinaires explicites rendent
un GooseArray. Val(tuple) demande une forme statique, tandis que le Val(rang)
interne à Base conserve sa sémantique de reshape par rang pour les vues.
Les conversions sans copie conservent l'état de portée du stockage original.

Le broadcasting possède un style statique qui compose les formes et les
dimensions singleton. Le mélange avec des formes dynamiques revient au style
dynamique. L'extension LinearAlgebra construit directement un résultat statique
pour les produits de deux matrices statiques ou matrice–vecteur statiques, puis
appelle mul!. Les produits réels de dimensions 1 à 4 ont une boucle native courte ;
les tailles supérieures utilisent BLAS. Un dot réel court utilise une réduction SIMD,
et un dot réel de plus de 2 048 éléments utilise BLAS.

L'allocation vérifie le type, le produit des dimensions sans débordement,
l'alignement réel de l'adresse et la capacité. Le curseur n'avance qu'après
validation. Les éléments sont contigus et stockés dans l'ordre colonne Julia.
L'alignement utilise `Base.datatype_alignment`, interface interne Julia à
surveiller lors des changements de version.

## Portées et invalidation

À l'entrée d'une portée, on conserve le curseur, active un emplacement de
génération et lui attribue un identifiant monotone. Chaque tableau retient cet
état de portée et cet identifiant. À la sortie, l'emplacement est invalidé et le curseur
restauré dans un `finally`. Les tableaux des niveaux extérieurs restent valides.
Une portée suivante au même niveau reçoit un identifiant différent : une vieille
référence ne redevient pas valide lorsque son adresse est réutilisée. La référence
directe à `_ScopeState` évite de rechercher le niveau dans un tampon de tableau
à chaque accès et sépare les champs de génération des données des tableaux.

Le compteur ne reboucle jamais silencieusement : son épuisement lève une erreur.
`reset!` remplace la génération racine. `close` retire sa génération en la mettant
à zéro, puis annule l'adresse du mapping. La finalisation retire toutes les
générations actives, y compris lors d'un appel explicite à `finalize` en portée imbriquée.
close et reset! sont interdits à l'intérieur d'une portée imbriquée.
Les accès aux éléments et aux pointeurs vérifient propriétaire et génération.
Tout descripteur publié porte un identifiant non nul : l'égalité des générations
prouve aussi que le mapping est ouvert, sans charger son adresse à chaque accès.
Les allocations, reset et entrées dans une portée vérifient toujours l'ouverture.
Les requêtes de forme (`size`, `length`) restent utilisables après invalidation :
elles lisent seulement les métadonnées du descripteur.

Les conversions d'éléments peuvent exécuter du code utilisateur. `setindex!` et
`fill!` revérifient donc la validité après conversion, pour empêcher une écriture
si cette conversion ferme ou réinitialise l'arène. Les pointeurs échappés et la
mutation directe des champs internes sortent de ce contrat de sécurité.

## Interface et choix de conception

Le supertype `DenseArray{T,N}` exprime la contiguïté. `IndexLinear()` et les
méthodes scalaires alimentent les interfaces génériques Julia : indexation
cartésienne, vues, masques, itération et réductions. Les opérations créant un
tableau passent par `similar` ou le style de broadcast et utilisent l'arène
active. Les opérations C/BLAS conservent le descripteur via `cconvert`.

`Base.dataids`, autre interface interne, fournit un identifiant du bloc mémoire
pour reconnaître les alias et éviter des copies inutiles en broadcasting. Les
copies contiguës entre GooseArray de même type utilisent `memmove` afin de gérer
les recouvrements. Un `reshape` conserve propriétaire, adresse et génération.

## Vectorisation des accès vérifiés

Les écritures via `unsafe_store!` ont une annotation d'alias très générale : le
compilateur doit envisager qu'elles modifient les métadonnées vérifiées au tour
suivant. `payload.jl` utilise la catégorie LLVM interne `jtbaa_arraybuf` pour les
écritures des types scalaires usuels. Les générations sont des champs d'objets
Julia, distincts des tampons de données. Le compilateur peut alors sortir les
contrôles d'une boucle dont le corps ne les modifie pas, puis vectoriser.

La catégorie choisie est la même que celle des tampons `Array`, afin de préserver
les alias avec `unsafe_wrap(Array, pointer(a), ...)`. Une catégorie privée qui
déclarerait tous les tampons disjoints serait incorrecte. Les tests incluent des
boucles avec dépendance entre un GooseArray et un Array enveloppant le même bloc.
Les appels inconnus ou les mutations de métadonnées restent des obstacles au
déplacement des contrôles. Aucune annotation ne déclare les générations immuables.

Ce chemin concerne Bool, les entiers natifs de 8 à 128 bits, Float16/32/64, Char,
ComplexF32 et ComplexF64. Les autres types isbits conservent un stockage générique.
L'arbre TBAA est un détail interne : l'optimisation est activée sur Julia 1.13.x,
testée sur 1.13.3, et désactivée au profit du chemin portable pour les autres versions.
Elle ne fournit pas de promesse de performances identiques pour tous les types.

Les allocations de données ne demandent ni `Vector` ni `Memory` Julia. Ce modèle
n'élimine ni le GC de Julia ni la compilation JIT. La pile est une région de
mémoire virtuelle, distincte de la pile native du processeur.

## Matérialisation sans collecte générique

Pour un résultat dont le type est concret, isbits et de taille positive, map
alloue la forme exacte une seule fois puis parcourt les indices prouvés valides.
La boucle ne teste pas les bornes à chaque élément. Elle vérifie le stockage
avant la lecture, puis après le callback et la conversion, avant toute écriture.
Les appels purs permettent le déplacement de ces contrôles par le compilateur.
Les types de résultat inconnus gardent la collecte générique Julia, et la forme
statique est rétablie sans copie. Le broadcast unaire de même forme partage ce
chemin ; les autres broadcasts conservent la fusion et l’indexation de Base. Leur résultat
neuf ne nécessite pas l’analyse d’alias de destination du chemin en place ;
les types inconnus conservent le repli générique complet.

Le map! unaire public entre tableaux Goose utilise cette même boucle indexée,
avec min(length(dest), length(src)) itérations, même entre rangs différents.
Une destination plus longue conserve sa fin. Une boucle vide ne touche aucun
stockage. Le callback précède le contrôle de la destination et sa conversion,
comme l'affectation de Base ; la destination est revérifiée après conversion.
Les alias suivent l'ordre des indices et ne sont pas déclarés indépendants.

Les chemins numériques natifs ne concernent que Float32/Float64 : leur
arithmétique ne peut pas appeler du code utilisateur. Les propriétaires et
générations sont vérifiés une fois, les indices découlent des dimensions validées
et GC.@preserve conserve tous les propriétaires pendant les accès bruts.
Les opérateurs scalaires personnalisés restent dans les chemins génériques.

## Opérandes partagés et entrées multiples (0.6)

Un état de portée appartient à une seule arène. Après validation d’un opérande,
les descripteurs ayant le même état doivent encore présenter le même jeton.
Une portée distincte garde son contrôle de génération ; une arène distincte
garde son contrôle de tâche. Cette preuve ne traverse pas un callback.
Les boucles de map revérifient les sources avant lecture puis la destination
après le callback et la conversion.

Les tuples d’opérandes sont développés selon leur arité et leurs types,
jamais leurs longueurs dynamiques ou identités d’arène. Les formes suivent
zip/Base : longueur minimale des vecteurs, vecteur en cas de rangs différents,
promotion des formes pour des rangs supérieurs identiques. Le résultat est alloué
dans l’arène du premier argument à la portée active. Les entrées toutes statiques
gardent une forme statique ; les autres mélanges donnent un GooseArray.
Un type de résultat inconnu ou non pris en charge garde la collecte de Base.

La réduction globale + numérique utilise un adaptateur privé AbstractVector,
contenant la fonction, les opérandes et une longueur Int. Son getindex vérifie
les sources et calcule une valeur ; aucun élément mappé n’est stocké. La réduction
pairwise/SIMD, les cas vides et init sont traités par Base. Les opérateurs ou init
personnalisés et les réductions par dimensions gardent une matérialisation suivie
d’une réduction standard. Les map restent immédiats et sum(map(...)) garde
son stockage intermédiaire.

Les produits matrice–vecteur réels ont un chemin natif jusqu’à 8 par dimension
dynamique, ou 16 pour une matrice statique dont les dimensions permettent un
développement borné. Les dimensions vides gardent les conventions de Base.
Comme pour mul! de Base, la destination ne doit pas aliaser les entrées.
axpy!/axpby! acceptent les alias exacts et gardent BLAS au-delà de 2 048 éléments.
Le stockage reste mmap ; aucune de ces optimisations ne le transforme en tuple
inline ou en pile native.
