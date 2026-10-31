# Comparaison des cinq vecteurs — GooseArrays (mesures du prototype devenu v0.1)

Mesures du 31 octobre 2026 : **1406 cas** (996 historiques + 410 complémentaires), **6030 tests réussis**, Julia 1.13.3 sur Apple M5 Max. Une Task Julia et un thread BLAS.

Chaque cellule donne **temps médian en nanosecondes / octets alloués par le GC**.
L'initialisation de l'arène et la compilation sont exclues de ces opérations et mesurées séparément.
`—` signifie **non exécuté**, jamais zéro. Les écarts de quelques pourcents peuvent être du bruit.

Les cinq vecteurs sont mesurés aux longueurs 2, 3, 4, 8, 16, 32, 64, 100 et 1 000.
Les cas MVector de 10 000 et 100 000 éléments sont exclus de cette campagne, afin de limiter
l'expansion de code et la compilation des algorithmes StaticArrays. StaticGooseArray y est mesuré.

### Mapping, réductions et broadcasting des vecteurs

Le mapping est `map(x -> 2x+1, b)`, la réduction `mapreduce(abs2,+,b)`. La somme fusionnée est `sum(x -> 2x+1, b)` et ne crée pas de résultat intermédiaire.
Les opérations hors place sont suivies d'une somme pour consommer le résultat : ce sont
des mesures du pipeline complet. Pour les arènes, elles comprennent aussi l'entrée/sortie de portée.

| Taille | Opération | Vector | FixedSizeVector | GooseVector | StaticGooseVector | MVector |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 2 | map! en place | 2.6 / 0 | 2.4 / 0 | 2.9 / 0 | 2.9 / 0 | 1.5 / 0 |
| 2 | map puis somme | 7.5 / 80 | 5.9 / 48 | 13.6 / 0 | 11.3 / 0 | 1.5 / 0 |
| 2 | somme fusionnée f | 1.8 / 0 | 2.0 / 0 | 2.8 / 0 | 2.2 / 0 | 1.4 / 0 |
| 2 | réduction abs2 | 2.8 / 0 | 2.4 / 0 | 2.8 / 0 | 2.7 / 0 | 1.5 / 0 |
| 2 | broadcast en place | 2.9 / 0 | 2.9 / 0 | 6.2 / 0 | 6.1 / 0 | 1.5 / 0 |
| 2 | broadcast puis somme | 7.9 / 80 | 5.8 / 48 | 13.5 / 0 | 11.3 / 0 | 1.5 / 0 |
| 2 | 2 .* b .+ 1 puis somme | 7.8 / 80 | 5.9 / 48 | 13.3 / 0 | 11.0 / 0 | 1.3 / 0 |
| 3 | map! en place | 2.8 / 0 | 2.8 / 0 | 3.3 / 0 | 3.0 / 0 | 1.6 / 0 |
| 3 | map puis somme | 8.1 / 80 | 6.0 / 48 | 13.8 / 0 | 13.7 / 0 | 1.6 / 0 |
| 3 | somme fusionnée f | 1.8 / 0 | 2.0 / 0 | 2.8 / 0 | 2.7 / 0 | 1.7 / 0 |
| 3 | réduction abs2 | 3.0 / 0 | 2.6 / 0 | 2.8 / 0 | 2.7 / 0 | 1.5 / 0 |
| 3 | broadcast en place | 3.1 / 0 | 3.1 / 0 | 6.4 / 0 | 5.9 / 0 | 1.8 / 0 |
| 3 | broadcast puis somme | 8.4 / 80 | 6.2 / 48 | 13.9 / 0 | 13.5 / 0 | 1.8 / 0 |
| 3 | 2 .* b .+ 1 puis somme | 8.3 / 80 | 6.1 / 48 | 13.9 / 0 | 13.7 / 0 | 1.5 / 0 |
| 4 | map! en place | 3.0 / 0 | 3.0 / 0 | 3.4 / 0 | 3.2 / 0 | 1.8 / 0 |
| 4 | map puis somme | 8.6 / 96 | 9.1 / 64 | 14.2 / 0 | 13.9 / 0 | 1.8 / 0 |
| 4 | somme fusionnée f | 2.3 / 0 | 2.2 / 0 | 3.2 / 0 | 2.7 / 0 | 1.8 / 0 |
| 4 | réduction abs2 | 3.2 / 0 | 3.0 / 0 | 3.2 / 0 | 2.7 / 0 | 1.5 / 0 |
| 4 | broadcast en place | 3.2 / 0 | 3.3 / 0 | 6.7 / 0 | 6.2 / 0 | 1.8 / 0 |
| 4 | broadcast puis somme | 8.9 / 96 | 6.8 / 64 | 14.2 / 0 | 14.1 / 0 | 1.5 / 0 |
| 4 | 2 .* b .+ 1 puis somme | 8.7 / 96 | 6.6 / 64 | 14.1 / 0 | 14.4 / 0 | 1.6 / 0 |
| 8 | map! en place | 2.5 / 0 | 2.5 / 0 | 3.3 / 0 | 3.7 / 0 | 2.0 / 0 |
| 8 | map puis somme | 10.3 / 128 | 9.2 / 96 | 14.7 / 0 | 15.1 / 0 | 2.0 / 0 |
| 8 | somme fusionnée f | 3.5 / 0 | 3.0 / 0 | 4.2 / 0 | 2.8 / 0 | 2.0 / 0 |
| 8 | réduction abs2 | 3.9 / 0 | 4.3 / 0 | 4.1 / 0 | 2.9 / 0 | 1.7 / 0 |
| 8 | broadcast en place | 3.2 / 0 | 3.3 / 0 | 6.5 / 0 | 7.1 / 0 | 1.8 / 0 |
| 8 | broadcast puis somme | 9.2 / 128 | 7.1 / 96 | 14.3 / 0 | 15.2 / 0 | 2.0 / 0 |
| 8 | 2 .* b .+ 1 puis somme | 9.0 / 128 | 7.0 / 96 | 14.6 / 0 | 14.6 / 0 | 2.0 / 0 |
| 16 | map! en place | 2.7 / 0 | 2.8 / 0 | 3.8 / 0 | 4.8 / 0 | 3.0 / 0 |
| 16 | map puis somme | 13.6 / 192 | 11.6 / 160 | 17.8 / 0 | 16.8 / 0 | 2.8 / 0 |
| 16 | somme fusionnée f | 4.3 / 0 | 4.3 / 0 | 5.8 / 0 | 4.8 / 0 | 2.8 / 0 |
| 16 | réduction abs2 | 5.2 / 0 | 5.2 / 0 | 5.8 / 0 | 4.8 / 0 | 2.2 / 0 |
| 16 | broadcast en place | 3.9 / 0 | 3.8 / 0 | 7.1 / 0 | 8.0 / 0 | 2.5 / 0 |
| 16 | broadcast puis somme | 12.6 / 192 | 10.0 / 160 | 17.5 / 0 | 16.2 / 0 | 2.8 / 0 |
| 16 | 2 .* b .+ 1 puis somme | 12.5 / 192 | 10.0 / 160 | 17.9 / 0 | 17.1 / 0 | 2.8 / 0 |
| 32 | map! en place | 3.5 / 0 | 3.7 / 0 | 5.0 / 0 | 4.7 / 0 | 5.2 / 0 |
| 32 | map puis somme | 16.0 / 320 | 13.9 / 288 | 18.9 / 0 | 16.9 / 0 | 5.5 / 0 |
| 32 | somme fusionnée f | 5.3 / 0 | 5.5 / 0 | 6.8 / 0 | 5.9 / 0 | 5.5 / 0 |
| 32 | réduction abs2 | 5.7 / 0 | 6.1 / 0 | 6.3 / 0 | 5.8 / 0 | 3.7 / 0 |
| 32 | broadcast en place | 5.2 / 0 | 5.1 / 0 | 8.6 / 0 | 7.8 / 0 | 4.2 / 0 |
| 32 | broadcast puis somme | 15.5 / 320 | 13.1 / 288 | 18.3 / 0 | 16.6 / 0 | 5.5 / 0 |
| 32 | 2 .* b .+ 1 puis somme | 15.1 / 320 | 12.9 / 288 | 18.8 / 0 | 16.3 / 0 | 5.5 / 0 |
| 64 | map! en place | 5.1 / 0 | 5.5 / 0 | 7.0 / 0 | 6.9 / 0 | 9.3 / 0 |
| 64 | map puis somme | 21.0 / 576 | 18.6 / 544 | 20.8 / 0 | 20.4 / 0 | 13.7 / 0 |
| 64 | somme fusionnée f | 6.9 / 0 | 7.1 / 0 | 8.4 / 0 | 7.7 / 0 | 11.3 / 0 |
| 64 | réduction abs2 | 7.0 / 0 | 7.0 / 0 | 7.4 / 0 | 6.8 / 0 | 9.0 / 0 |
| 64 | broadcast en place | 7.2 / 0 | 7.2 / 0 | 11.4 / 0 | 11.4 / 0 | 14.3 / 0 |
| 64 | broadcast puis somme | 21.3 / 576 | 18.8 / 544 | 21.0 / 0 | 19.8 / 0 | 13.7 / 0 |
| 64 | 2 .* b .+ 1 puis somme | 21.0 / 576 | 18.5 / 544 | 21.1 / 0 | 19.8 / 0 | 13.7 / 0 |
| 100 | map! en place | 8.1 / 0 | 8.0 / 0 | 9.4 / 0 | 9.4 / 0 | 14.0 / 0 |
| 100 | map puis somme | 25.9 / 928 | 24.1 / 896 | 24.4 / 0 | 23.0 / 0 | 26.6 / 0 |
| 100 | somme fusionnée f | 9.4 / 0 | 9.4 / 0 | 9.5 / 0 | 9.7 / 0 | 20.1 / 0 |
| 100 | réduction abs2 | 7.6 / 0 | 7.2 / 0 | 8.1 / 0 | 6.8 / 0 | 16.5 / 0 |
| 100 | broadcast en place | 9.2 / 0 | 9.4 / 0 | 16.8 / 0 | 14.9 / 0 | 26.5 / 0 |
| 100 | broadcast puis somme | 26.4 / 928 | 24.5 / 896 | 24.9 / 0 | 22.2 / 0 | 26.6 / 0 |
| 100 | 2 .* b .+ 1 puis somme | 27.4 / 928 | 25.2 / 896 | 25.2 / 0 | 22.8 / 0 | 26.6 / 0 |
| 1000 | map! en place | 66.2 / 0 | 67.7 / 0 | 66.8 / 0 | 66.5 / 0 | 133.1 / 0 |
| 1000 | map puis somme | 217.0 / 8256 | 211.0 / 8224 | 156.1 / 0 | 152.7 / 0 | 589.8 / 0 |
| 1000 | somme fusionnée f | 87.7 / 0 | 87.7 / 0 | 87.8 / 0 | 87.8 / 0 | 421.9 / 0 |
| 1000 | réduction abs2 | 79.2 / 0 | 78.5 / 0 | 77.9 / 0 | 79.2 / 0 | 409.8 / 0 |
| 1000 | broadcast en place | 67.8 / 0 | 69.5 / 0 | 73.7 / 0 | 71.2 / 0 | 283.7 / 0 |
| 1000 | broadcast puis somme | 196.4 / 8256 | 194.4 / 8224 | 156.2 / 0 | 153.4 / 0 | 590.0 / 0 |
| 1000 | 2 .* b .+ 1 puis somme | 195.9 / 8256 | 194.2 / 8224 | 156.1 / 0 | 152.6 / 0 | 589.6 / 0 |
| 10000 | map! en place | 779.0 / 0 | 686.9 / 0 | 697.7 / 0 | 720.6 / 0 | — |
| 10000 | map puis somme | 2259.2 / 81984 | 2263.9 / 81952 | 1641.7 / 0 | 1620.8 / 0 | — |
| 10000 | somme fusionnée f | 891.9 / 0 | 896.7 / 0 | 890.0 / 0 | 889.2 / 0 | — |
| 10000 | réduction abs2 | 962.3 / 0 | 973.6 / 0 | 961.2 / 0 | 960.3 / 0 | — |
| 10000 | broadcast en place | 705.1 / 0 | 669.5 / 0 | 783.8 / 0 | 725.9 / 0 | — |
| 10000 | broadcast puis somme | 2222.2 / 81984 | 2158.3 / 81952 | 1641.7 / 0 | 1625.0 / 0 | — |
| 10000 | 2 .* b .+ 1 puis somme | 2287.1 / 81984 | 2150.0 / 81952 | 1637.5 / 0 | 1633.3 / 0 | — |
| 100000 | map! en place | 12125.0 / 0 | 12250.0 / 0 | 12084.0 / 0 | 12277.7 / 0 | — |
| 100000 | map puis somme | 22125.0 / 802880 | 22125.0 / 802848 | 20417.0 / 0 | 20375.0 / 0 | — |
| 100000 | somme fusionnée f | 8847.0 / 0 | 8819.3 / 0 | 8861.3 / 0 | 8875.0 / 0 | — |
| 100000 | réduction abs2 | 10000.0 / 0 | 10000.0 / 0 | 9958.0 / 0 | 9959.0 / 0 | — |
| 100000 | broadcast en place | 12083.0 / 0 | 12292.0 / 0 | 12125.0 / 0 | 12042.0 / 0 | — |
| 100000 | broadcast puis somme | 21791.0 / 802880 | 21791.0 / 802848 | 20417.0 / 0 | 20375.0 / 0 | — |
| 100000 | 2 .* b .+ 1 puis somme | 21791.0 / 802880 | 21792.0 / 802848 | 20375.0 / 0 | 20500.0 / 0 | — |

### Multiplication matricielle

Matrices carrées Float64. `mul!` utilise une destination préallouée ; `* puis somme`
inclut la construction et la consommation du résultat. MMatrix n'est exécuté que jusqu'à 16×16.

| Taille | Opération | Matrix | FixedSizeMatrix | GooseMatrix | StaticGooseMatrix | MMatrix |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 2×2 | mul! en place | 12.4 / 0 | 18.2 / 0 | 9.2 / 0 | 6.0 / 0 | 2.3 / 0 |
| 2×2 | * puis somme | 19.3 / 112 | 47.1 / 64 | 20.3 / 0 | 17.5 / 0 | 1.6 / 0 |
| 3×3 | mul! en place | 14.1 / 0 | 19.5 / 0 | 15.5 / 0 | 7.7 / 0 | 3.2 / 0 |
| 3×3 | * puis somme | 22.7 / 144 | 49.7 / 96 | 25.1 / 0 | 19.3 / 0 | 2.5 / 0 |
| 4×4 | mul! en place | 45.5 / 0 | 49.0 / 0 | 28.3 / 0 | 10.8 / 0 | 3.7 / 0 |
| 4×4 | * puis somme | 54.6 / 208 | 66.2 / 160 | 39.3 / 0 | 23.7 / 0 | 3.6 / 0 |
| 8×8 | mul! en place | 84.4 / 0 | 86.6 / 0 | 81.9 / 0 | 79.6 / 0 | 28.3 / 0 |
| 8×8 | * puis somme | 95.2 / 592 | 106.4 / 544 | 102.8 / 0 | 91.3 / 0 | 76.7 / 0 |
| 16×16 | mul! en place | 232.1 / 0 | 235.0 / 0 | 228.3 / 0 | 225.5 / 0 | 220.4 / 0 |
| 16×16 | * puis somme | 285.3 / 2128 | 309.2 / 2080 | 268.2 / 0 | 256.2 / 0 | 294.6 / 0 |
| 64×64 | mul! en place | 19042.0 / 0 | 20708.0 / 0 | 19209.0 / 0 | 19125.0 / 0 | — |
| 64×64 | * puis somme | 21208.0 / 32848 | 19625.0 / 32800 | 19500.0 / 0 | 19417.0 / 0 | — |
| 256×256 | mul! en place | 653979.0 / 0 | 655292.0 / 0 | 653145.5 / 0 | 656021.0 / 0 | — |
| 256×256 | * puis somme | 666083.0 / 524368 | 659292.0 / 524320 | 660541.0 / 0 | 659458.0 / 0 | — |

Les autres opérations, les allocations de construction, SVector/SMatrix et la spécialisation
sont détaillés dans les sections suivantes et les CSV sous `benchmark/reference/m5-max-2026-10-31/`.

### Plusieurs entrées et mises à l’échelle

Fonctions : f₂(x,y)=x*y et f₃(x,y,z)=x+y*z. Les lignes map puis somme restent deux opérations,
avec matérialisation du résultat. Les mapreduce globaux natifs + ne stockent plus les éléments mappés.
Pour Goose, les opérations hors place et les réductions multi-entrées gardent la même portée par
appel dans les quatre campagnes, y compris après suppression du temporaire. axpy! utilise α=0,25 ;
axpby! utilise α=0,25 et β=0,5. Ces 410 cas ont les mêmes noyaux à chaque étape.

| Taille | Opération | Vector | FixedSizeVector | GooseVector | StaticGooseVector | MVector |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 2 | map! deux entrées | 4.2 / 0 | 2.5 / 0 | 3.0 / 0 | 3.0 / 0 | 3.7 / 0 |
| 2 | map! trois entrées | 6.4 / 0 | 6.8 / 0 | 3.8 / 0 | 3.5 / 0 | 3.8 / 0 |
| 2 | map deux entrées puis somme | 9.5 / 80 | 10.1 / 80 | 15.4 / 0 | 12.4 / 0 | 1.6 / 0 |
| 2 | map trois entrées puis somme | 10.3 / 80 | 10.9 / 80 | 15.7 / 0 | 12.2 / 0 | 1.5 / 0 |
| 2 | mapreduce deux entrées | 9.5 / 80 | 10.2 / 80 | 12.8 / 0 | 11.8 / 0 | 1.5 / 0 |
| 2 | mapreduce trois entrées | 10.2 / 80 | 11.0 / 80 | 13.2 / 0 | 11.3 / 0 | 1.5 / 0 |
| 2 | axpy! | 5.1 / 0 | 5.9 / 0 | 3.0 / 0 | 4.0 / 0 | 3.8 / 0 |
| 2 | axpby! | 4.8 / 0 | 5.0 / 0 | 3.0 / 0 | 4.7 / 0 | 4.2 / 0 |
| 3 | map! deux entrées | 4.4 / 0 | 3.0 / 0 | 3.2 / 0 | 3.1 / 0 | 3.7 / 0 |
| 3 | map! trois entrées | 6.6 / 0 | 7.2 / 0 | 4.1 / 0 | 3.7 / 0 | 3.8 / 0 |
| 3 | map deux entrées puis somme | 10.0 / 80 | 10.6 / 80 | 15.4 / 0 | 15.3 / 0 | 1.5 / 0 |
| 3 | map trois entrées puis somme | 10.8 / 80 | 11.4 / 80 | 15.3 / 0 | 14.8 / 0 | 1.8 / 0 |
| 3 | mapreduce deux entrées | 10.0 / 80 | 10.6 / 80 | 12.8 / 0 | 11.7 / 0 | 1.6 / 0 |
| 3 | mapreduce trois entrées | 10.8 / 80 | 11.4 / 80 | 13.2 / 0 | 11.4 / 0 | 1.6 / 0 |
| 3 | axpy! | 5.4 / 0 | 6.0 / 0 | 3.2 / 0 | 4.1 / 0 | 3.6 / 0 |
| 3 | axpby! | 5.3 / 0 | 5.2 / 0 | 3.1 / 0 | 4.7 / 0 | 4.3 / 0 |
| 4 | map! deux entrées | 5.0 / 0 | 3.0 / 0 | 3.5 / 0 | 3.3 / 0 | 3.9 / 0 |
| 4 | map! trois entrées | 6.8 / 0 | 7.4 / 0 | 4.4 / 0 | 4.0 / 0 | 4.0 / 0 |
| 4 | map deux entrées puis somme | 10.5 / 96 | 10.9 / 96 | 15.5 / 0 | 15.7 / 0 | 1.8 / 0 |
| 4 | map trois entrées puis somme | 11.2 / 96 | 11.9 / 96 | 15.7 / 0 | 15.2 / 0 | 1.8 / 0 |
| 4 | mapreduce deux entrées | 10.4 / 96 | 10.9 / 96 | 12.8 / 0 | 11.5 / 0 | 1.8 / 0 |
| 4 | mapreduce trois entrées | 11.2 / 96 | 12.0 / 96 | 13.5 / 0 | 11.8 / 0 | 1.8 / 0 |
| 4 | axpy! | 5.8 / 0 | 6.3 / 0 | 3.4 / 0 | 4.1 / 0 | 3.8 / 0 |
| 4 | axpby! | 5.3 / 0 | 5.3 / 0 | 3.3 / 0 | 4.8 / 0 | 4.3 / 0 |
| 8 | map! deux entrées | 5.8 / 0 | 4.2 / 0 | 3.5 / 0 | 3.9 / 0 | 4.8 / 0 |
| 8 | map! trois entrées | 6.6 / 0 | 7.0 / 0 | 4.2 / 0 | 4.8 / 0 | 5.5 / 0 |
| 8 | map deux entrées puis somme | 11.9 / 128 | 12.3 / 128 | 15.9 / 0 | 16.1 / 0 | 2.0 / 0 |
| 8 | map trois entrées puis somme | 13.0 / 128 | 13.6 / 128 | 17.1 / 0 | 16.3 / 0 | 2.3 / 0 |
| 8 | mapreduce deux entrées | 11.8 / 128 | 12.3 / 128 | 12.8 / 0 | 11.2 / 0 | 2.0 / 0 |
| 8 | mapreduce trois entrées | 13.0 / 128 | 13.8 / 128 | 13.7 / 0 | 11.4 / 0 | 2.3 / 0 |
| 8 | axpy! | 6.9 / 0 | 7.6 / 0 | 3.4 / 0 | 4.3 / 0 | 4.0 / 0 |
| 8 | axpby! | 5.5 / 0 | 5.5 / 0 | 3.9 / 0 | 4.8 / 0 | 4.7 / 0 |
| 16 | map! deux entrées | 6.6 / 0 | 5.0 / 0 | 4.2 / 0 | 5.3 / 0 | 6.4 / 0 |
| 16 | map! trois entrées | 7.5 / 0 | 7.7 / 0 | 5.2 / 0 | 7.6 / 0 | 9.5 / 0 |
| 16 | map deux entrées puis somme | 15.5 / 192 | 16.1 / 192 | 18.2 / 0 | 17.9 / 0 | 2.7 / 0 |
| 16 | map trois entrées puis somme | 17.0 / 192 | 17.7 / 192 | 19.0 / 0 | 18.5 / 0 | 3.5 / 0 |
| 16 | mapreduce deux entrées | 14.8 / 192 | 15.1 / 192 | 19.0 / 0 | 15.7 / 0 | 2.7 / 0 |
| 16 | mapreduce trois entrées | 16.3 / 192 | 17.1 / 192 | 21.6 / 0 | 18.6 / 0 | 3.5 / 0 |
| 16 | axpy! | 8.5 / 0 | 9.4 / 0 | 4.2 / 0 | 6.0 / 0 | 5.8 / 0 |
| 16 | axpby! | 6.0 / 0 | 5.9 / 0 | 4.5 / 0 | 6.5 / 0 | 6.0 / 0 |
| 64 | map! deux entrées | 10.5 / 0 | 8.9 / 0 | 8.2 / 0 | 7.8 / 0 | 15.1 / 0 |
| 64 | map! trois entrées | 14.4 / 0 | 12.7 / 0 | 11.2 / 0 | 10.6 / 0 | 20.8 / 0 |
| 64 | map deux entrées puis somme | 23.3 / 576 | 23.9 / 576 | 22.2 / 0 | 20.5 / 0 | 13.3 / 0 |
| 64 | map trois entrées puis somme | 26.0 / 576 | 26.2 / 576 | 26.3 / 0 | 24.3 / 0 | 16.8 / 0 |
| 64 | mapreduce deux entrées | 23.4 / 576 | 23.0 / 576 | 20.7 / 0 | 18.0 / 0 | 10.9 / 0 |
| 64 | mapreduce trois entrées | 25.5 / 576 | 25.5 / 576 | 25.8 / 0 | 22.6 / 0 | 14.1 / 0 |
| 64 | axpy! | 10.6 / 0 | 10.7 / 0 | 8.1 / 0 | 7.7 / 0 | 7.6 / 0 |
| 64 | axpby! | 10.8 / 0 | 10.5 / 0 | 8.4 / 0 | 8.3 / 0 | 8.1 / 0 |
| 1000 | map! deux entrées | 95.3 / 0 | 93.3 / 0 | 93.0 / 0 | 92.9 / 0 | 177.0 / 0 |
| 1000 | map! trois entrées | 128.0 / 0 | 126.0 / 0 | 124.9 / 0 | 124.2 / 0 | 252.9 / 0 |
| 1000 | map deux entrées puis somme | 227.3 / 8256 | 230.1 / 8256 | 168.7 / 0 | 168.9 / 0 | 621.4 / 0 |
| 1000 | map trois entrées puis somme | 249.2 / 8256 | 261.9 / 8256 | 204.3 / 0 | 203.8 / 0 | 772.7 / 0 |
| 1000 | mapreduce deux entrées | 227.7 / 8256 | 231.1 / 8256 | 105.0 / 0 | 103.9 / 0 | 441.2 / 0 |
| 1000 | mapreduce trois entrées | 249.6 / 8256 | 261.5 / 8256 | 138.8 / 0 | 136.2 / 0 | 523.0 / 0 |
| 1000 | axpy! | 86.1 / 0 | 87.5 / 0 | 92.4 / 0 | 92.2 / 0 | 93.0 / 0 |
| 1000 | axpby! | 94.4 / 0 | 94.4 / 0 | 92.6 / 0 | 92.0 / 0 | 93.3 / 0 |
| 10000 | map! deux entrées | 1600.0 / 0 | 1720.8 / 0 | 1733.4 / 0 | 1333.3 / 0 | — |
| 10000 | map! trois entrées | 2408.4 / 0 | 2449.0 / 0 | 2279.2 / 0 | 1795.9 / 0 | — |
| 10000 | map deux entrées puis somme | 2884.3 / 81984 | 2870.3 / 81984 | 2361.1 / 0 | 2365.8 / 0 | — |
| 10000 | map trois entrées puis somme | 3614.5 / 81984 | 3609.4 / 81984 | 3083.3 / 0 | 3069.4 / 0 | — |
| 10000 | mapreduce deux entrées | 2888.9 / 81984 | 2819.4 / 81984 | 1065.1 / 0 | 1064.1 / 0 | — |
| 10000 | mapreduce trois entrées | 3645.8 / 81984 | 3625.0 / 81984 | 1629.1 / 0 | 1620.9 / 0 | — |
| 10000 | axpy! | 1395.8 / 0 | 1470.8 / 0 | 1362.5 / 0 | 1481.2 / 0 | — |
| 10000 | axpby! | 1454.2 / 0 | 1533.3 / 0 | 1529.2 / 0 | 1529.1 / 0 | — |
| 100000 | map! deux entrées | 18291.5 / 0 | 18958.0 / 0 | 18917.0 / 0 | 18875.0 / 0 | — |
| 100000 | map! trois entrées | 25125.0 / 0 | 25125.0 / 0 | 25083.0 / 0 | 25125.0 / 0 | — |
| 100000 | map deux entrées puis somme | 28375.0 / 802880 | 28375.0 / 802880 | 27791.0 / 0 | 27833.0 / 0 | — |
| 100000 | map trois entrées puis somme | 34916.0 / 802880 | 35042.0 / 802880 | 33917.0 / 0 | 33875.0 / 0 | — |
| 100000 | mapreduce deux entrées | 28334.0 / 802880 | 28417.0 / 802880 | 12458.0 / 0 | 12459.0 / 0 | — |
| 100000 | mapreduce trois entrées | 35000.0 / 802880 | 34875.0 / 802880 | 19291.0 / 0 | 19333.0 / 0 | — |
| 100000 | axpy! | 15417.0 / 0 | 15375.0 / 0 | 15250.0 / 0 | 15375.0 / 0 | — |
| 100000 | axpby! | 15375.0 / 0 | 15375.0 / 0 | 15417.0 / 0 | 15458.0 / 0 | — |

### Matrice–vecteur

Matrice carrée n×n et vecteurs de n éléments. mul! a une destination préallouée ;
* puis somme inclut l’allocation et la consommation du résultat, comme pour les matrices.

| Taille | Opération | Matrix × Vector | FixedSizeMatrix × FixedSizeVector | GooseMatrix × GooseVector | StaticGooseMatrix × StaticGooseVector | MMatrix × MVector |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 2×2 | mul! matrice–vecteur | 19.7 / 0 | 19.4 / 0 | 6.2 / 0 | 4.2 / 0 | 5.2 / 0 |
| 2×2 | * puis somme | 28.3 / 80 | 27.5 / 48 | 19.5 / 0 | 16.7 / 0 | 1.6 / 0 |
| 3×3 | mul! matrice–vecteur | 30.4 / 0 | 31.7 / 0 | 7.4 / 0 | 4.7 / 0 | 5.7 / 0 |
| 3×3 | * puis somme | 38.7 / 80 | 38.7 / 48 | 20.6 / 0 | 17.7 / 0 | 1.8 / 0 |
| 4×4 | mul! matrice–vecteur | 21.5 / 0 | 20.0 / 0 | 11.0 / 0 | 5.1 / 0 | 6.5 / 0 |
| 4×4 | * puis somme | 29.2 / 96 | 28.0 / 64 | 21.5 / 0 | 17.6 / 0 | 2.1 / 0 |
| 8×8 | mul! matrice–vecteur | 34.5 / 0 | 34.8 / 0 | 23.3 / 0 | 10.9 / 0 | 14.1 / 0 |
| 8×8 | * puis somme | 46.5 / 128 | 44.9 / 96 | 34.9 / 0 | 20.6 / 0 | 4.5 / 0 |
| 16×16 | mul! matrice–vecteur | 65.9 / 0 | 65.3 / 0 | 70.5 / 0 | 16.7 / 0 | 42.5 / 0 |
| 16×16 | * puis somme | 78.9 / 192 | 77.6 / 160 | 106.1 / 0 | 25.8 / 0 | 19.6 / 0 |
| 64×64 | mul! matrice–vecteur | 453.1 / 0 | 452.9 / 0 | 456.2 / 0 | 455.2 / 0 | — |
| 64×64 | * puis somme | 605.8 / 576 | 607.4 / 544 | 502.6 / 0 | 469.5 / 0 | — |
| 256×256 | mul! matrice–vecteur | 7708.2 / 0 | 7708.4 / 0 | 7718.8 / 0 | 7718.8 / 0 | — |
| 256×256 | * puis somme | 8078.1 / 2112 | 7927.2 / 2080 | 7770.8 / 0 | 7750.0 / 0 | — |

## Environnement exact

```text
GooseArrays: 0.6.0 (version mesurée avant renumérotation v0.1.0)
Julia: 1.13.3; kernel: Darwin; architecture: aarch64
CPU: Apple M5 Max
Julia threads: 1; BLAS threads: 1
FixedSizeArrays: 1.5.1
StaticArrays: 1.9.24
BenchmarkTools: 1.8.0
Seconds per case: 0.25; max samples: 3000
Lengths: 2,3,4,8,16,32,64,100,1000,10000,100000; StaticArrays max: 1000
Square matrix sides: 2,3,4,8,16,64,256
BLAS: LBTConfig([ILP64] libopenblas64_.0.3.30.dylib)
```


Campagne complémentaire :

```text
GooseArrays=0.6.0 (version mesurée avant renumérotation v0.1.0)
Julia=1.13.3
CPU=Apple M5 Max
BLAS=LBTConfig([ILP64] libopenblas64_.0.3.30.dylib)
threads=1, BLAS=1
seconds=0.25, samples=3000
lengths=2,3,4,8,16,64,1000,10000,100000
StaticGoose max=100000
sides=2,3,4,8,16,64,256
```

Les quatre bibliothèques sont Base, FixedSizeArrays, GooseArrays et StaticArrays.
Les cinq colonnes utilisent des vecteurs modifiables. Les variantes immuables SVector
et SMatrix sont des références supplémentaires, pas des substituts aux opérations en place.

## Construction, accès et opérations complémentaires

Unités : nanosecondes / octets GC. La construction échappante stocke dans Ref{Any} ;
les arènes incluent reset! pour réutiliser le stockage. La construction + calcul remplit
de 2 puis réduit. Elle peut être optimisée fortement quand la longueur est connue.

| Taille | Opération | Vector | FixedSizeVector | GooseVector | StaticGooseVector | MVector |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 2 | construction échappante | 6.7 / 80 | 7.7 / 80 | 7.5 / 64 | 9.4 / 48 | 3.4 / 32 |
| 2 | construction + remplissage + somme | 8.1 / 80 | 6.0 / 48 | 13.5 / 0 | 11.0 / 0 | 3.7 / 32 |
| 2 | fill! | 1.5 / 0 | 1.4 / 0 | 2.9 / 0 | 2.8 / 0 | 1.1 / 0 |
| 2 | sum | 1.8 / 0 | 1.2 / 0 | 2.2 / 0 | 2.0 / 0 | 1.1 / 0 |
| 2 | indexation | 1.1 / 0 | 1.3 / 0 | 2.2 / 0 | 2.3 / 0 | 1.1 / 0 |
| 2 | copyto! | 2.8 / 0 | 3.0 / 0 | 5.8 / 0 | 4.6 / 0 | 1.5 / 0 |
| 2 | dot | 6.2 / 0 | 6.5 / 0 | 2.5 / 0 | 2.2 / 0 | 1.1 / 0 |
| 2 | boucle affine | 2.0 / 0 | 2.2 / 0 | 2.9 / 0 | 2.7 / 0 | 1.5 / 0 |
| 2 | broadcast expression en place | 3.0 / 0 | 2.9 / 0 | 6.4 / 0 | 5.4 / 0 | 1.4 / 0 |
| 3 | construction échappante | 7.0 / 80 | 8.1 / 80 | 7.4 / 64 | 9.4 / 48 | 3.4 / 32 |
| 3 | construction + remplissage + somme | 9.0 / 80 | 7.8 / 48 | 14.7 / 0 | 14.7 / 0 | 3.7 / 32 |
| 3 | fill! | 1.8 / 0 | 1.8 / 0 | 4.1 / 0 | 4.5 / 0 | 1.1 / 0 |
| 3 | sum | 1.3 / 0 | 1.5 / 0 | 2.3 / 0 | 2.3 / 0 | 1.1 / 0 |
| 3 | indexation | 1.1 / 0 | 1.3 / 0 | 2.2 / 0 | 2.2 / 0 | 1.1 / 0 |
| 3 | copyto! | 3.0 / 0 | 3.1 / 0 | 5.9 / 0 | 4.9 / 0 | 1.7 / 0 |
| 3 | dot | 6.6 / 0 | 6.8 / 0 | 2.5 / 0 | 2.2 / 0 | 1.3 / 0 |
| 3 | boucle affine | 2.4 / 0 | 2.5 / 0 | 3.3 / 0 | 3.0 / 0 | 1.6 / 0 |
| 3 | broadcast expression en place | 3.0 / 0 | 3.1 / 0 | 6.4 / 0 | 5.9 / 0 | 1.8 / 0 |
| 4 | construction échappante | 7.3 / 96 | 8.3 / 96 | 7.2 / 64 | 9.4 / 48 | 3.6 / 48 |
| 4 | construction + remplissage + somme | 15.8 / 96 | 9.3 / 64 | 13.8 / 0 | 13.7 / 0 | 3.8 / 48 |
| 4 | fill! | 2.0 / 0 | 2.0 / 0 | 3.2 / 0 | 2.9 / 0 | 1.0 / 0 |
| 4 | sum | 1.8 / 0 | 1.3 / 0 | 2.8 / 0 | 2.3 / 0 | 1.1 / 0 |
| 4 | indexation | 1.1 / 0 | 1.2 / 0 | 2.2 / 0 | 2.2 / 0 | 1.1 / 0 |
| 4 | copyto! | 3.2 / 0 | 3.5 / 0 | 6.1 / 0 | 4.9 / 0 | 1.6 / 0 |
| 4 | dot | 6.9 / 0 | 7.0 / 0 | 2.6 / 0 | 2.2 / 0 | 1.3 / 0 |
| 4 | boucle affine | 2.4 / 0 | 2.6 / 0 | 3.5 / 0 | 3.0 / 0 | 1.8 / 0 |
| 4 | broadcast expression en place | 3.2 / 0 | 3.3 / 0 | 6.7 / 0 | 6.1 / 0 | 1.8 / 0 |
| 8 | construction échappante | 8.1 / 128 | 8.7 / 128 | 7.4 / 64 | 9.6 / 48 | 4.0 / 80 |
| 8 | construction + remplissage + somme | 9.6 / 128 | 7.5 / 96 | 15.0 / 0 | 14.7 / 0 | 4.4 / 80 |
| 8 | fill! | 1.5 / 0 | 1.7 / 0 | 3.9 / 0 | 3.8 / 0 | 1.2 / 0 |
| 8 | sum | 2.6 / 0 | 2.2 / 0 | 3.7 / 0 | 2.3 / 0 | 1.3 / 0 |
| 8 | indexation | 1.1 / 0 | 1.3 / 0 | 2.2 / 0 | 2.2 / 0 | 0.9 / 0 |
| 8 | copyto! | 2.8 / 0 | 3.4 / 0 | 6.0 / 0 | 5.2 / 0 | 2.1 / 0 |
| 8 | dot | 7.8 / 0 | 7.8 / 0 | 2.5 / 0 | 2.2 / 0 | 1.3 / 0 |
| 8 | boucle affine | 2.4 / 0 | 2.3 / 0 | 3.3 / 0 | 3.7 / 0 | 2.0 / 0 |
| 8 | broadcast expression en place | 3.2 / 0 | 3.2 / 0 | 6.5 / 0 | 7.1 / 0 | 1.8 / 0 |
| 16 | construction échappante | 14.0 / 192 | 20.6 / 192 | 7.7 / 64 | 9.6 / 48 | 10.3 / 144 |
| 16 | construction + remplissage + somme | 14.2 / 192 | 10.0 / 160 | 17.3 / 0 | 15.1 / 0 | 5.5 / 144 |
| 16 | fill! | 1.8 / 0 | 2.1 / 0 | 3.9 / 0 | 3.8 / 0 | 1.5 / 0 |
| 16 | sum | 5.0 / 0 | 3.9 / 0 | 5.1 / 0 | 4.1 / 0 | 1.5 / 0 |
| 16 | indexation | 1.1 / 0 | 1.3 / 0 | 2.4 / 0 | 2.2 / 0 | 1.1 / 0 |
| 16 | copyto! | 3.1 / 0 | 3.8 / 0 | 6.7 / 0 | 5.8 / 0 | 3.1 / 0 |
| 16 | dot | 9.8 / 0 | 9.5 / 0 | 3.0 / 0 | 2.8 / 0 | 2.0 / 0 |
| 16 | boucle affine | 2.5 / 0 | 2.8 / 0 | 3.9 / 0 | 4.8 / 0 | 2.9 / 0 |
| 16 | broadcast expression en place | 3.9 / 0 | 3.8 / 0 | 7.0 / 0 | 8.2 / 0 | 2.5 / 0 |
| 32 | construction échappante | 21.2 / 320 | 32.0 / 320 | 7.6 / 64 | 9.7 / 48 | 6.0 / 272 |
| 32 | construction + remplissage + somme | 17.6 / 320 | 12.3 / 288 | 19.0 / 0 | 17.1 / 0 | 8.0 / 272 |
| 32 | fill! | 2.8 / 0 | 3.2 / 0 | 5.0 / 0 | 4.8 / 0 | 2.4 / 0 |
| 32 | sum | 5.8 / 0 | 5.0 / 0 | 5.7 / 0 | 4.4 / 0 | 2.3 / 0 |
| 32 | indexation | 1.1 / 0 | 1.3 / 0 | 2.3 / 0 | 2.2 / 0 | 1.1 / 0 |
| 32 | copyto! | 4.2 / 0 | 5.0 / 0 | 7.4 / 0 | 6.5 / 0 | 5.2 / 0 |
| 32 | dot | 7.8 / 0 | 7.8 / 0 | 4.4 / 0 | 4.0 / 0 | 3.0 / 0 |
| 32 | boucle affine | 3.5 / 0 | 3.5 / 0 | 4.9 / 0 | 4.4 / 0 | 3.0 / 0 |
| 32 | broadcast expression en place | 5.2 / 0 | 5.0 / 0 | 8.7 / 0 | 7.5 / 0 | 4.2 / 0 |
| 64 | construction échappante | 18.3 / 576 | 20.0 / 576 | 7.8 / 64 | 10.0 / 48 | 7.3 / 544 |
| 64 | construction + remplissage + somme | 22.6 / 576 | 17.6 / 544 | 21.0 / 0 | 21.0 / 0 | 15.1 / 544 |
| 64 | fill! | 4.5 / 0 | 5.0 / 0 | 7.2 / 0 | 7.5 / 0 | 4.1 / 0 |
| 64 | sum | 6.9 / 0 | 5.7 / 0 | 7.0 / 0 | 6.0 / 0 | 5.9 / 0 |
| 64 | indexation | 0.9 / 0 | 1.3 / 0 | 2.4 / 0 | 2.3 / 0 | 0.9 / 0 |
| 64 | copyto! | 6.4 / 0 | 7.1 / 0 | 9.3 / 0 | 9.0 / 0 | 4.8 / 0 |
| 64 | dot | 10.3 / 0 | 10.4 / 0 | 6.9 / 0 | 6.9 / 0 | 5.5 / 0 |
| 64 | boucle affine | 5.2 / 0 | 5.6 / 0 | 6.9 / 0 | 6.7 / 0 | 4.8 / 0 |
| 64 | broadcast expression en place | 7.2 / 0 | 7.2 / 0 | 11.9 / 0 | 9.6 / 0 | 14.3 / 0 |
| 100 | construction échappante | 18.7 / 928 | 20.2 / 928 | 7.7 / 64 | 9.7 / 48 | 8.2 / 816 |
| 100 | construction + remplissage + somme | 25.1 / 928 | 23.8 / 896 | 23.8 / 0 | 22.5 / 0 | 30.3 / 816 |
| 100 | fill! | 7.1 / 0 | 7.4 / 0 | 9.2 / 0 | 9.0 / 0 | 8.1 / 0 |
| 100 | sum | 6.4 / 0 | 6.2 / 0 | 7.2 / 0 | 6.4 / 0 | 11.7 / 0 |
| 100 | indexation | 1.1 / 0 | 1.1 / 0 | 2.3 / 0 | 2.2 / 0 | 0.9 / 0 |
| 100 | copyto! | 8.2 / 0 | 9.0 / 0 | 11.5 / 0 | 11.3 / 0 | 7.3 / 0 |
| 100 | dot | 13.8 / 0 | 14.1 / 0 | 10.1 / 0 | 10.0 / 0 | 8.5 / 0 |
| 100 | boucle affine | 7.8 / 0 | 8.2 / 0 | 9.5 / 0 | 9.4 / 0 | 7.4 / 0 |
| 100 | broadcast expression en place | 9.2 / 0 | 9.4 / 0 | 16.1 / 0 | 12.6 / 0 | 26.5 / 0 |
| 1000 | construction échappante | 39.0 / 8256 | 38.4 / 8256 | 7.8 / 64 | 9.8 / 48 | 26.1 / 8064 |
| 1000 | construction + remplissage + somme | 177.5 / 8256 | 176.7 / 8224 | 140.9 / 0 | 140.5 / 0 | 582.2 / 8064 |
| 1000 | fill! | 56.0 / 0 | 56.4 / 0 | 57.9 / 0 | 57.5 / 0 | 105.8 / 0 |
| 1000 | sum | 64.5 / 0 | 62.7 / 0 | 64.2 / 0 | 63.3 / 0 | 402.6 / 0 |
| 1000 | indexation | 1.1 / 0 | 1.2 / 0 | 2.3 / 0 | 2.4 / 0 | 1.1 / 0 |
| 1000 | copyto! | 68.1 / 0 | 70.0 / 0 | 71.2 / 0 | 71.4 / 0 | 65.1 / 0 |
| 1000 | dot | 102.1 / 0 | 99.3 / 0 | 89.6 / 0 | 87.4 / 0 | 88.8 / 0 |
| 1000 | boucle affine | 70.8 / 0 | 69.0 / 0 | 67.2 / 0 | 66.7 / 0 | 65.2 / 0 |
| 1000 | broadcast expression en place | 67.3 / 0 | 66.8 / 0 | 73.8 / 0 | 72.4 / 0 | 284.0 / 0 |
| 10000 | construction échappante | 183.3 / 81984 | 186.4 / 81984 | 8.2 / 64 | 9.9 / 48 | — |
| 10000 | construction + remplissage + somme | 1566.6 / 81984 | 1554.2 / 81952 | 1225.0 / 0 | 1208.3 / 0 | — |
| 10000 | fill! | 604.8 / 0 | 631.9 / 0 | 546.8 / 0 | 546.3 / 0 | — |
| 10000 | sum | 662.1 / 0 | 655.4 / 0 | 640.9 / 0 | 638.8 / 0 | — |
| 10000 | indexation | 1.1 / 0 | 1.2 / 0 | 2.4 / 0 | 2.4 / 0 | — |
| 10000 | copyto! | 610.2 / 0 | 608.8 / 0 | 638.4 / 0 | 603.4 / 0 | — |
| 10000 | dot | 1225.0 / 0 | 1154.1 / 0 | 1106.3 / 0 | 1112.8 / 0 | — |
| 10000 | boucle affine | 742.9 / 0 | 694.5 / 0 | 701.2 / 0 | 722.7 / 0 | — |
| 10000 | broadcast expression en place | 776.6 / 0 | 751.9 / 0 | 724.4 / 0 | 777.2 / 0 | — |
| 100000 | construction échappante | 570.9 / 802880 | 544.7 / 802880 | 8.4 / 64 | 10.0 / 48 | — |
| 100000 | construction + remplissage + somme | 15125.0 / 802880 | 14625.0 / 802848 | 13750.0 / 0 | 13542.0 / 0 | — |
| 100000 | fill! | 5597.2 / 0 | 5576.3 / 0 | 5451.3 / 0 | 5437.5 / 0 | — |
| 100000 | sum | 7175.0 / 0 | 7158.2 / 0 | 7216.6 / 0 | 7198.0 / 0 | — |
| 100000 | indexation | 1.0 / 0 | 1.4 / 0 | 2.4 / 0 | 2.2 / 0 | — |
| 100000 | copyto! | 8722.0 / 0 | 8680.7 / 0 | 8680.7 / 0 | 8722.0 / 0 | — |
| 100000 | dot | 12291.0 / 0 | 12250.0 / 0 | 12291.0 / 0 | 12291.0 / 0 | — |
| 100000 | boucle affine | 11625.0 / 0 | 12167.0 / 0 | 12083.0 / 0 | 12042.0 / 0 | — |
| 100000 | broadcast expression en place | 9625.0 / 0 | 12292.0 / 0 | 12000.0 / 0 | 12125.0 / 0 | — |

La construction en portée, sans échappement, est mesurée séparément dans le CSV pour les
deux variantes Goose. Les octets de données consommés dans l'arène y sont aussi indiqués.
Zéro octet GC ne signifie pas zéro mémoire utilisée : les éléments occupent 8×n octets
pour ces Float64, auxquels s'ajoutent les métadonnées initiales et les descripteurs éventuels.

## Références immuables StaticArrays

| n | SVector somme | SVector réduction abs2 | SVector map puis somme | SVector broadcast puis somme |
| ---: | ---: | ---: | ---: | ---: |
| 2 | 1.1 / 0 | 1.5 / 0 | 1.4 / 0 | 1.5 / 0 |
| 3 | 0.9 / 0 | 1.5 / 0 | 1.7 / 0 | 1.5 / 0 |
| 4 | 1.1 / 0 | 1.5 / 0 | 1.8 / 0 | 1.5 / 0 |
| 8 | 1.3 / 0 | 1.6 / 0 | 1.9 / 0 | 1.9 / 0 |
| 16 | 1.5 / 0 | 2.1 / 0 | 2.5 / 0 | 2.5 / 0 |
| 32 | 2.3 / 0 | 3.7 / 0 | 5.2 / 0 | 5.2 / 0 |
| 64 | 5.9 / 0 | 9.3 / 0 | 13.2 / 0 | 13.2 / 0 |
| 100 | 11.7 / 0 | 17.0 / 0 | 25.4 / 0 | 25.1 / 0 |
| 1000 | 378.3 / 0 | 420.7 / 0 | 602.3 / 0 | 631.9 / 0 |

SMatrix `* puis somme` est aussi fourni dans le CSV pour les petites matrices.

## Compilation et spécialisation

Processus neuf ; construction des entrées et chargement des packages exclus. Le premier
appel est exécuté via invokelatest pour inclure la compilation du noyau contrôlé.
Les temps dépendent de l'ordre et du compilateur : ils ne constituent pas un benchmark
complet du démarrage. Les comptes sont des MethodInstance, pas un inventaire des CodeInstance.

| Famille | Formes testées | Types concrets | Instances finales du noyau | Compilation cumulée du noyau (ms) |
| --- | ---: | ---: | ---: | ---: |
| Array | 11 | 1 | 1 | 4.080 |
| FixedSizeArray | 11 | 1 | 1 | 15.825 |
| GooseArray | 11 | 1 | 1 | 7.212 |
| StaticGooseArray | 11 | 11 | 11 | 73.773 |
| MVector | 9 | 9 | 9 | 54.738 |
| SVector | 9 | 9 | 9 | 25.656 |

GooseArray conserve un type pour toutes les longueurs testées. StaticGooseArray et
StaticArrays spécialisent volontairement par forme. Les générations et identités d'arène
ne sont pas des paramètres ; les tests contrôlent les recréations de mêmes formes.

## Validation et limites

**6030 assertions réussies** via Pkg.test avec --check-bounds=yes. Les tests
couvrent les formes, conversions sans copie, alias, portées imbriquées, réemploi de mémoire,
callbacks qui invalident l'arène, opérations matricielles, allocations et spécialisation.
Les deux types Goose conservent des contrôles de durée de vie, même sous @inbounds ;
leurs bornes peuvent néanmoins être désactivées par @inbounds comme dans Julia.

Les résultats concernent des noyaux typés après échauffement. L'arène et ses états sont
alloués une fois ; les descripteurs vérifiés peuvent allouer lorsqu'ils s'échappent.
Les tailles statiques n'impliquent ni un tuple inline ni un placement sur la pile native.
L'optimisation LLVM est activée sur Julia 1.13.x, testée sur 1.13.3 ; les autres versions
ont un chemin portable. Le type statique ne garantit pas un gain dans chaque opération.

Les benchmarks sont des cas distincts, toutes familles et tailles confondues. Leur nombre
ne représente pas le nombre de victoires d'un type. Les minimums et percentiles 95 sont
disponibles dans le CSV ; les tableaux présentent les médianes. La mémoire RSS et les pages
physiques ne sont pas mesurées. Aucune comparaison de vitesse directe avec le langage Goose.


## Reproduire les mesures

La version publiée `0.1.0` reprend le code de la dernière itération du prototype,
qui portait encore le numéro interne `0.6.0` au moment de ces mesures. Ces CSV
sont des **mesures de référence historiques**, pas des garanties universelles.
Les valeurs brutes et les conditions de mesure sont dans
`benchmark/reference/m5-max-2026-10-31/`.

Depuis la racine du dépôt :

```sh
julia --startup-file=no benchmark/bench.jl
julia --startup-file=no benchmark/bench.jl --full
```

Le premier lance une sélection courte ; le second relance les deux campagnes
complètes. Les sorties sont écrites dans `benchmark/results/` (non versionné).
Pour choisir un autre répertoire : `--out chemin/vers/dossier`.

La mesure de `map` hors place inclut la consommation du résultat ; côté Goose,
elle inclut le retour de portée. Un `0` pour les allocations GC ne signifie pas
qu'aucun octet n'est consommé dans l'arène. Les descripteurs échappants et
l'initialisation peuvent allouer sur le tas GC. Les comparaisons dépendent de
la machine, de la version Julia et du contexte d'exécution.
