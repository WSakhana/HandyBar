# HandyBar — Kit CurseForge / Mise en PROD

Date: 2026-02-10
Version: 1.1.1
Game: World of Warcraft Retail (Interface 120000)

---

## Titre (addon name)
HandyBar

## Slogan (1 ligne)
Le tracker de cooldowns d’arène 100% manuel, pensé pour les joueurs PvP.

## Description courte (CurseForge Summary)
HandyBar est une alternative “manual-first” à OmniBar : vous cliquez sur une icône quand vous voyez un sort ennemi partir, et HandyBar lance le cooldown (avec texte + spirale), filtré par ennemis détectés en arène.

## Description longue (CurseForge Description)
HandyBar est un addon de suivi manuel des cooldowns en arènes PvP.

Contrairement à un tracker automatique, HandyBar vous laisse le contrôle :
- Quand vous voyez un sort ennemi partir, vous cliquez sur l’icône correspondante.
- L’addon démarre le timer (texte + spirale), et vous pouvez réinitialiser à la demande.

Fonctionnalités:
- Barres configurables (taille, espacement, croissance, limite d’icônes, etc.)
- Visible en arène uniquement (sauf Mode Test)
- Détection des classes/spés ennemies via l’API d’arène Retail (prep) + fallback UnitClass
- Filtrage par barre: All Enemies / Arena1 / Arena2 / Arena3
- Duplication optionnelle si plusieurs ennemis partagent une classe/spé
- Bordure colorée par classe (option)
- Gestion des sorts à charges (si supportés par MajorCooldowns)
- Overrides de durée de cooldown (globaux)
- Ajout de sorts personnalisés (SpellID + cooldown + class/spec/category)
- Profils AceDB

Commandes:
- /hb : options
- /hb test : toggle Mode Test
- /hb lock : verrouiller/déverrouiller
- /hb reset : reset des cooldowns actifs

Dépendances:
- Ace3 + MajorCooldowns embarqués dans le dossier Libs/ (aucun téléchargement requis)

Notes:
- HandyBar ne “détecte” pas automatiquement les sorts lancés: c’est volontaire.
- Si vous oubliez de cliquer, le cooldown ne démarre pas.

## Mots-clés (tags à copier)
PvP, Arena, Cooldowns, Manual, OmniBar alternative, Tracker

---

## Idée de logo (simple, lisible en 64x64)
Concept: une petite barre d’icônes (3 carrés alignés) + un sablier stylisé ("manual time tracking") en surimpression.
- Formes simples, gros contrastes, lisible en très petit.
- Éviter toute iconographie Blizzard/WoW existante (pas d’icônes de sorts, pas d’assets du jeu).

## Prompt (génération logo)
Tu peux utiliser ce prompt tel quel dans un générateur d’images:

"Create a clean, original vector-style app icon for an addon named HandyBar. The icon shows three small rounded squares aligned horizontally to suggest a cooldown bar, with a simple hourglass overlay centered. Minimal shapes, high contrast, thick strokes, no text, no game assets, no copyrighted Blizzard/WoW imagery. Flat design, transparent background, centered composition, readable at 64x64."

Variantes:
- Remplacer le sablier par un curseur de souris (clic) + petit arc de cooldown.
- Ajouter 3 marqueurs 'Arena1/2/3' sous forme de points (3 dots) (sans chiffres).

---

## Checklist PROD (avant upload)

1) Versioning
- Mettre à jour `## Version` dans le TOC (déjà: 1.1.1)
- Mettre à jour le README si tu affiches la version (déjà: 1.1.1)
- Ajouter une entrée dans CHANGELOG.md (déjà fait)

2) Packaging
- Le zip doit contenir: `HandyBar/` à la racine du zip
- À l’intérieur: `HandyBar.toc`, `Core.lua`, `Options.lua`, `Modules/`, `Locale/`, `Libs/`

3) CurseForge
- Coller la description courte + longue
- Ajouter au moins 1 screenshot (optionnel mais fortement conseillé)
- Renseigner la/les versions de jeu supportées (Retail 12.x)

4) QA rapide
- Lancer le jeu, /reload
- Ouvrir `/hb`, activer Mode Test: vérifier affichage + clics
- Entrer en arène (ou skirmish) et activer “Debug Mode” si besoin

---

## Notes de publication (Release Notes)
"Release polish: debug output consistency + test mode safely disables on zone changes."
