class LudoRules {
  static const List<Map<String, String>> rules = [
    {
      'title': 'Lancer des dés',
      'content':
          '• On lance 2 dés. \n'
          '• **Seul le double 6 (6+6) donne droit à relancer !**\n'
          '• Les autres doubles (1+1, 2+2...) sont joués normalement sans relance.\n'
          '• En cas de 6+6, on cumule et on relance.',
    },
    {
      'title': 'Sortir un pion',
      'content':
          '• Il faut un **6 sur un seul dé** pour sortir.\n'
          '• **Mouvement Automatique** : Si **aucun autre pion** ne peut bouger, le pion sorti doit jouer tous les dés restants (ex: 6+3 = 9 cases).\n'
          '• Sinon, vous êtes libre d\'utiliser vos autres dés sur vos pions déjà en jeu.',
    },
    {
      'title': 'Blocage à la sortie',
      'content':
          '• Si **2 pions ou plus** bloquent votre sortie, vous ne pouvez pas sortir normalement.\n'
          '• **Coup Spécial** : Pour débloquer, il faut autant de **6** que d\'adversaires ET autant de pions disponibles (Maison/Prison). Tous sortent ensemble et capturent le blocage.',
    },
    {
      'title': 'Avancer',
      'content':
          '• On répartit les dés sur ses pions comme on veut.\n'
          '• **Stratégie** : Cliquez sur plusieurs dés pour les **combiner** et bouger un seul pion de leur somme.',
    },
    {
      'title': 'Mouvement COMBINÉ (Téléportation)',
      'content':
          '• **Direct** : Quand vous combinez les dés (ex: 5+5), le pion se "téléporte" directement à destination.\n'
          '• **Saut** : Il ignore complètement les adversaires sur les cases intermédiaires.\n'
          '• **Capture** : Il ne capture que s\'il atterrit **exactement** sur la case finale.',
    },
    {
      'title': 'Mouvement SÉPARÉ & Protection',
      'content':
          '• **Séquentiel** : Jouer les dés un par un permet de capturer sur des cases intermédiaires.\n'
          '• **Règle de Protection** : Si une capture immobilise votre pion alors qu\'il reste des dés à jouer et qu\'aucun autre pion ne peut bouger, le système **force la combinaison** et annule la capture pour éviter le blocage.',
    },
    {
      'title': 'Barrages et Obstacles',
      'content':
          '• Aucun mouvement, même combiné, ne peut sauter par-dessus un **barrage** (2 pions adverses).\n'
          '• Les cases marquées d\'un symbole protègent contre la capture.',
    },
    {
      'title': 'Capturer & Prison',
      'content':
          '• Les capturés vont au **centre de VOTRE base** (en prison).\n'
          '• Pour sortir de prison, il faut un **6** pour racheter le pion, puis un autre **6** pour rentrer sur le plateau.',
    },
    {
      'title': 'Blocage (Pont)',
      'content':
          '• Impossible de passer ou de s\'arrêter sur un blocage (2+ pions adverses).\n'
          '• **Fin de partie** : Si un joueur est coincé derrière un blocage avec son dernier pion, l\'adversaire a l\'**obligation** d\'ouvrir son pont progressivement.',
    },
    {
      'title': 'Zones Sûres',
      'content': '• Les cases marquées protègent de la capture.',
    },
    {
      'title': 'Nombre de joueurs',
      'content':
          '• Le Ludo peut se jouer de **2 à 4 joueurs**.\n'
          '• Chaque joueur choisit une couleur et joue avec ses 4 pions.',
    },
    {
      'title': 'Victoire',
      'content':
          '• Amener ses 4 pions au centre.\n'
          '• Le premier joueur à finir gagne.',
    },
  ];
}
