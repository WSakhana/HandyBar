# HandyBar (Retail 12+ / Interface 120000)

HandyBar est un addon **de suivi manuel des cooldowns** pour les arènes PvP sur World of Warcraft (Retail).

Contrairement aux trackers “automatiques”, HandyBar vous demande d’**indiquer vous‑même** qu’un sort ennemi a été utilisé : vous **cliquez** sur l’icône du sort quand vous le voyez partir, et l’addon lance le décompte.

- Version indiquée par l’addon : `1.1.1`
- Variables sauvegardées : `HandyBarDB`
- Dépendances embarquées : Ace3 + MajorCooldowns (inclus dans le dossier `Libs/`)

---

## Fonctionnalités principales

- **Barres de sorts** configurables (taille, espacement, direction de croissance, limite d’icônes, etc.)
- **Filtrage arène** : les barres n’affichent des sorts que si l’addon est en arène (ou en mode test)
- **Détection des adversaires** (classe/spé) via l’API de préparation d’arène Retail
- **Filtre “All Enemies / Arena1 / Arena2 / Arena3”** par barre
- **Duplication d’icônes** si plusieurs adversaires partagent la même classe/spé (option par barre)
- **Texte de cooldown** sur les icônes, + **spirale de cooldown**
- **Bordure colorée par classe** (option)
- **Support des sorts à charges** (si le sort a plusieurs charges côté MajorCooldowns)
- **Overrides** de durée de cooldown (global, s’applique à toutes les barres)
- **Ajout de sorts personnalisés** (non présents dans MajorCooldowns)
- **Profils** AceDB (via l’onglet Profiles de Blizzard)

---

## Installation

1. Vérifiez que le dossier est bien placé ici :
   - `World of Warcraft/_retail_/Interface/AddOns/HandyBar/`
2. Le fichier TOC est : `HandyBar.toc` (Interface `120000`).
3. (Recommandé) Redémarrez le jeu ou faites `/reload`.

---

## Démarrage rapide

1. Ouvrez la configuration :
   - `/hb`
2. Activez **Mode Test** pour voir toutes les barres et les sorts (hors arène).
3. Déverrouillez les barres (**Lock Bars** OFF), placez-les, puis reverrouillez.
4. Dans **Bars** → choisissez une barre → **Spells** : activez les sorts que vous voulez suivre.

---

## Utilisation en match

### Clics sur les icônes

- **Clic gauche** : démarre le cooldown (ou consomme une charge si le sort est à charges)
- **Clic droit** : réinitialise le cooldown (et restaure les charges)

### Quand les barres sont visibles

- En conditions normales, HandyBar n’affiche des icônes **qu’en arène**.
- Hors arène, vous ne voyez rien **sauf** si vous activez le **Mode Test**.

### Important : suivi manuel

HandyBar **ne détecte pas automatiquement** qu’un ennemi a lancé un sort. Le principe est volontairement “manual-first” :
- Si vous oubliez de cliquer, le cooldown ne démarre pas.
- Si un sort est “fake cast”, annulé, ou si vous n’êtes pas sûr, vous pouvez choisir de ne pas le cliquer.

---

## Commandes

- `/hb` : ouvre la configuration
- `/hb test` : active/désactive le **Mode Test**
- `/hb lock` : verrouille/déverrouille les barres
- `/hb reset` : réinitialise tous les cooldowns actifs

---

## Configuration (détaillée)

La configuration est fournie via AceConfig et apparaît dans l’interface Blizzard.

### Onglet “General”

- **Test Mode** : affiche toutes les barres + tous les sorts assignés, même hors arène
  - Le mode test est **runtime uniquement** : il **ne persiste pas** au rechargement, ni aux transitions (zone/arène).
- **Lock Bars** : empêche le déplacement des barres et masque le titre “draggable”
- **Debug Mode** : affiche des logs dans le chat (détection d’ennemis, visibilité, etc.)
- **Reset All Cooldowns** : remet à zéro tous les timers
- **Reset Configuration** : remet l’intégralité de la config (bars, sorts, overrides) aux valeurs par défaut

### Onglet “Bars”

#### Créer une nouvelle barre
- Entrez un nom → **Create Bar**

#### Réglages d’une barre (Appearance)
- **Enabled** : active/désactive la barre
- **Icon Size** : taille des icônes
- **Spacing** : espacement entre icônes
- **Max Icons Per Row** : nombre max d’icônes par ligne avant retour à la ligne
- **Icon Display Limit** : limite totale d’icônes affichées (0 = illimité)
- **Grow Direction** :
  - RIGHT/LEFT : lignes horizontales empilées verticalement
  - DOWN/UP : colonnes verticales empilées horizontalement
- **Show Cooldown Text** : affiche le temps restant au centre
- **Show Icon Border** : bordure colorée selon la classe

#### Actions
- **Reset Bar Cooldowns** : reset uniquement la barre
- **Reset Position** : recentre la barre à l’écran
- **Delete This Bar** : supprime la barre et ses réglages

### “Arena Visibility” (par barre)

- **Visibility Mode** :
  - **All Enemies** : affiche les sorts correspondant aux classes/spés détectées chez les adversaires
  - **Arena 1/2/3 Only** : filtre la barre pour ne considérer que l’adversaire dans ce slot

- **Duplicate Same Spec/Class** :
  - Si plusieurs ennemis partagent la même classe/spé, HandyBar peut afficher plusieurs fois la même icône (une par “match”), pour faciliter le tracking parallèle.

### “Spells” (sélection des sorts)

- La liste est organisée par **classe**, et regroupe les sorts par :
  - **All Specs** (sorts de classe)
  - une spé unique
  - **Multiple Specs**
  - **Unknown Spec** (si la spé ne peut pas être résolue)

Actions utiles :
- **Enable Default** : active les sorts marqués `defaultEnabled` côté MajorCooldowns
- **Disable All** : désactive tous les sorts de la classe pour cette barre

### Onglet “Customize”

#### Cooldown Overrides
Permet de modifier la durée par défaut d’un sort de MajorCooldowns.
- Les overrides sont **globaux** : ils s’appliquent à toutes les barres.
- Activer un override ajoute une entrée dans `durationOverrides[spellKey]`.
- La valeur est en secondes (plage 1 → 600 dans l’UI).

#### Custom Spells
Ajoute des sorts absents de MajorCooldowns.
- Champs : **Spell ID**, **Cooldown (seconds)**, **Class**, **Specialization**, **Category**
- Les sorts custom sont enregistrés sous une clé `custom_<SpellID>`.
- Ils deviennent ensuite sélectionnables dans la liste de sorts (onglet Bars → Spells).

---

## Fonctionnement interne (résumé technique)

### Création des barres par défaut
Au premier lancement (si aucune barre n’existe), HandyBar crée :
- **Defensives** : au-dessus du centre
- **Offensives** : en dessous du centre

Les sorts activés par défaut proviennent de MajorCooldowns :
- `DEFENSIVE` → Defensives
- `BURST` / `OFFENSIVE` → Offensives

### Détection des ennemis en arène
HandyBar s’appuie en priorité sur l’API “prep” Retail :
- `ARENA_PREP_OPPONENT_SPECIALIZATIONS`
- `GetNumArenaOpponentSpecs()` + `GetArenaOpponentSpec(i)`
- `GetSpecializationInfoByID(specID)` pour obtenir `classFile`

Fallback : si les specs ne sont pas dispo, il tente `UnitClass("arenaX")`.

### Visibilité / filtrage
- Hors arène : rien n’est affiché (sauf **Mode Test**)
- En arène : pour chaque sort activé dans la barre, l’addon vérifie s’il “matche” une classe/spé ennemie détectée.

### Timers & charges
- Les cooldowns sont gérés par AceTimer.
- Pour les sorts à charges (`stack > 1` côté MajorCooldowns), HandyBar démarre un timer de recharge par charge consommée.

---

## Dépannage

### Je ne vois aucune icône en arène
1. Vérifiez que la barre est **Enabled**.
2. Vérifiez que des sorts sont activés : Bars → (votre barre) → Spells.
3. Activez **Debug Mode** et entrez en arène :
   - vous devez voir des logs “DetectArenaOpponents” et des classes détectées.
4. Testez hors arène avec **Mode Test** pour valider la mise en page.

### Mes barres disparaissent hors arène
C’est attendu : HandyBar est conçu pour n’afficher les barres **qu’en arène**, sauf en **Mode Test**.

### Le Mode Test se désactive tout seul
C’est volontaire : il est **non persistant** et est forcé OFF lors des reloads et transitions (et à l’entrée en arène réelle).

---

## Localisation

- Anglais : `enUS` (locale par défaut)
- Français : `frFR`

---

## Fichiers importants

- `HandyBar.toc` : métadonnées, Interface 120000, ordre de chargement
- `Core.lua` : DB, slash commands, defaults, overrides & custom spells
- `Modules/Arena.lua` : détection ennemis en arène
- `Modules/Bar.lua` : frames, layout, clics, timers, visibilité
- `Modules/TestMode.lua` : mode test runtime
- `Options.lua` : UI AceConfig

---

## Notes

Cet addon embarque Ace3 et MajorCooldowns dans `Libs/`.
Si vous modifiez des durées (Overrides) ou ajoutez des Custom Spells, pensez à vérifier que vos barres ont bien les sorts activés.
