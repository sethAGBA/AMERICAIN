# Règles d'Awale (Oware)

## Vue d'ensemble

Awale (aussi appelé Oware, Wari, ou Mancala) est un jeu de stratégie traditionnel africain pour deux joueurs. Le jeu se joue sur un plateau avec 12 trous et 48 graines.

## Objectif

Capturer plus de 25 graines (la majorité des 48 graines au total) pour gagner la partie.

## Configuration initiale

- **Plateau** : 12 trous disposés en 2 rangées de 6
  - Rangée du haut : trous 0-5 (adversaire)
  - Rangée du bas : trous 6-11 (joueur)
- **Graines** : 4 graines dans chaque trou au début (48 au total)
- **Joueurs** : 2 joueurs

## Déroulement du jeu

### Tour de jeu

1. **Sélection** : Le joueur actif choisit un trou de son côté contenant des graines
2. **Distribution** : Toutes les graines du trou choisi sont ramassées
3. **Semis** : Les graines sont distribuées une par une dans les trous suivants, dans le sens antihoraire
4. **Saut du trou d'origine** : Si le tour complet revient au trou de départ, on le saute et on continue

### Captures

Les captures se produisent lorsque :

1. **Condition de capture** : La dernière graine atterrit dans un trou de l'adversaire
2. **Nombre de graines** : Ce trou contient maintenant 2 ou 3 graines au total
3. **Capture multiple** : On continue à capturer en arrière si les trous précédents (dans le sens inverse) contiennent aussi 2 ou 3 graines
4. **Limite** : On s'arrête dès qu'on rencontre un trou avec un nombre différent de graines

**Exemple de capture** :
```
Si la dernière graine atterrit dans un trou adverse avec 1 graine (total = 2) :
→ Capturer ces 2 graines
→ Vérifier le trou précédent : s'il a 2 ou 3 graines, les capturer aussi
→ Continuer jusqu'à trouver un trou avec un nombre différent
```

## Règles spéciales

### 1. Règle anti-famine

**Interdiction** : Un joueur ne peut pas faire un coup qui laisse l'adversaire sans aucune graine.

**Raison** : L'adversaire doit toujours pouvoir jouer au tour suivant.

**Application** :
- Si tous les coups possibles affameraient l'adversaire, le joueur doit choisir un coup qui lui laisse au moins une graine
- Si aucun coup ne permet cela, la partie se termine et chaque joueur garde les graines de son côté

### 2. Règle du Grand Chelem

**Interdiction** : On ne peut pas capturer TOUTES les graines de l'adversaire en un seul coup.

**Application** :
- Si une capture viderait complètement le côté adverse, la capture est annulée
- Les graines restent dans les trous
- Le tour passe quand même

### 3. Fin de partie

La partie se termine quand :

1. **Victoire par capture** : Un joueur a capturé 25 graines ou plus
2. **Plateau vide** : Il ne reste plus de graines sur le plateau
3. **Impossibilité de jouer** : Un joueur ne peut plus faire de coup valide

**Décompte final** :
- Le joueur avec le plus de graines capturées gagne
- En cas d'égalité (24-24), c'est un match nul

## Stratégie de base

### Conseils pour débutants

1. **Contrôle du plateau** : Essayez de garder des graines sur votre côté pour avoir plus d'options
2. **Anticipation** : Pensez aux captures possibles 2-3 coups à l'avance
3. **Défense** : Évitez de laisser des trous avec 1 graine du côté adverse (faciles à capturer)
4. **Mobilité** : Gardez plusieurs trous avec des graines pour avoir plus de choix

### Tactiques avancées

1. **Piège à capture** : Créez des situations où l'adversaire est forcé de vous donner des captures
2. **Contrôle du tempo** : Forcez l'adversaire à jouer des coups défavorables
3. **Fin de partie** : Dans les derniers coups, calculez précisément pour maximiser vos captures

## Variantes

Cette implémentation suit les **règles traditionnelles Oware** (Afrique de l'Ouest), qui sont les plus courantes. D'autres variantes existent avec des règles légèrement différentes.

## Niveaux de difficulté du bot

- **Facile** : Coups aléatoires parmi les coups valides
- **Moyen** : Stratégie gourmande (maximise les captures immédiates)
- **Difficile** : Algorithme Minimax avec élagage alpha-bêta (anticipe plusieurs coups)

## Exemple de partie

```
Configuration initiale :
Adversaire: [4] [4] [4] [4] [4] [4]
Joueur:     [4] [4] [4] [4] [4] [4]
Captures: Adversaire: 0, Joueur: 0

Tour 1 - Joueur choisit trou 8 (3ème trou) :
Adversaire: [4] [4] [5] [5] [5] [5]
Joueur:     [4] [4] [0] [4] [4] [4]
Captures: Adversaire: 0, Joueur: 0

Tour 2 - Adversaire choisit trou 2 :
Adversaire: [4] [4] [0] [6] [6] [6]
Joueur:     [5] [5] [0] [4] [4] [4]
Captures: Adversaire: 0, Joueur: 0

... et ainsi de suite jusqu'à ce qu'un joueur atteigne 25 captures
```

## Notation

- **Trous** : Numérotés de 0 à 11
  - 0-5 : Rangée du haut (adversaire vu du bas)
  - 6-11 : Rangée du bas (joueur)
- **Sens de jeu** : Antihoraire (→)
- **Captures** : Notées entre parenthèses, ex: (+3) pour 3 graines capturées
