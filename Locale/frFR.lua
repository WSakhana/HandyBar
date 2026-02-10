------------------------------------------------------------------------
-- HandyBar - Locale: French
------------------------------------------------------------------------
local addonName, ns = ...

local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "frFR")
if not L then return end

------------------------------------------------------------------------
-- General
------------------------------------------------------------------------
L["HandyBar"] = "HandyBar"
L["ADDON_DESC"] = "|cff00ccffHandyBar|r est un addon de suivi de cooldowns manuel pour les Arènes PvP.\nCliquez sur les icônes des sorts ennemis lorsque vous les voyez utilisés pour commencer à suivre leurs cooldowns.\nClic droit pour réinitialiser un cooldown.\n"
L["General"] = "Général"
L["Bars"] = "Barres"
L["Customize"] = "Personnaliser"

------------------------------------------------------------------------
-- General Tab
------------------------------------------------------------------------
L["Test Mode"] = "Mode Test"
L["TEST_MODE_DESC"] = "Afficher toutes les barres et sorts pour tester la disposition. Le filtrage d'arène est ignoré.\n\n|cFFFF8800Note :|r Le mode test n'est pas persisté et est automatiquement désactivé lors des rechargements et changements de zone."
L["Test Mode enabled."] = "|cff00ff00Mode Test activé.|r Toutes les barres et sorts sont maintenant visibles."
L["Test Mode disabled."] = "|cffff0000Mode Test désactivé.|r"
L["Lock Bars"] = "Verrouiller les barres"
L["LOCK_BARS_DESC"] = "Empêcher le déplacement des barres. Masque les titres et l'arrière-plan."
L["Debug Mode"] = "Mode Debug"
L["DEBUG_MODE_DESC"] = "Afficher les messages de débogage dans le chat pour la détection des adversaires d'arène."
L["Debug mode enabled."] = "|cFF00FF00[HandyBar]|r Mode Debug activé. Vous verrez les messages de détection en arène."
L["Debug mode disabled."] = "|cFF00FF00[HandyBar]|r Mode Debug désactivé."
L["Reset All Cooldowns"] = "Réinitialiser tous les cooldowns"
L["RESET_ALL_CD_DESC"] = "Réinitialiser tous les cooldowns actifs sur chaque barre."
L["Reset all active cooldowns?"] = "Réinitialiser tous les cooldowns actifs ?"
L["All cooldowns reset."] = "Tous les cooldowns réinitialisés."
L["Reset Configuration"] = "Réinitialiser la configuration"
L["RESET_CONFIG_DESC"] = "Réinitialiser tous les paramètres de HandyBar (barres et sélections de sorts) aux valeurs par défaut."
L["RESET_CONFIG_CONFIRM"] = "Réinitialiser TOUTE la configuration HandyBar aux valeurs par défaut ?"
L["Configuration reset to defaults."] = "Configuration réinitialisée aux valeurs par défaut."

------------------------------------------------------------------------
-- Slash Commands
------------------------------------------------------------------------
L["SLASH_COMMANDS_DESC"] = "|cff888888Commandes :|r\n  |cff00ff00/hb|r          - Ouvrir la configuration\n  |cff00ff00/hb test|r      - Basculer le mode test\n  |cff00ff00/hb lock|r      - Basculer le verrouillage des barres\n  |cff00ff00/hb reset|r     - Réinitialiser tous les cooldowns\n"
L["HandyBar Commands:"] = "|cff00ff00Commandes HandyBar :|r"
L["CMD_CONFIG"] = "  /hb          - Ouvrir la configuration"
L["CMD_TEST"] = "  /hb test     - Basculer le mode test"
L["CMD_LOCK"] = "  /hb lock     - Basculer le verrouillage"
L["CMD_RESET"] = "  /hb reset    - Réinitialiser les cooldowns"

------------------------------------------------------------------------
-- Bars
------------------------------------------------------------------------
L["Create New Bar"] = "Créer une nouvelle barre"
L["Bar Name"] = "Nom de la barre"
L["BAR_NAME_DESC"] = "Entrez un nom unique pour la nouvelle barre."
L["Create Bar"] = "Créer la barre"
L["Please enter a bar name."] = "Veuillez entrer un nom de barre."
L["BAR_EXISTS"] = "Une barre nommée '%s' existe déjà !"
L["BAR_CREATED"] = "Barre '|cff00ff00%s|r' créée."
L["BAR_DELETED"] = "Barre '|cffff0000%s|r' supprimée."

------------------------------------------------------------------------
-- Bar Settings
------------------------------------------------------------------------
L["Settings"] = "Paramètres"
L["Appearance"] = "Apparence"
L["Enabled"] = "Activée"
L["ENABLED_DESC"] = "Activer ou désactiver cette barre."
L["Icon Size"] = "Taille des icônes"
L["ICON_SIZE_DESC"] = "Taille des icônes de sorts en pixels."
L["Spacing"] = "Espacement"
L["SPACING_DESC"] = "Espace entre les icônes en pixels."
L["Max Icons Per Row"] = "Icônes max par ligne"
L["MAX_PER_ROW_DESC"] = "Nombre maximum d'icônes par ligne. La barre passera à plusieurs lignes si nécessaire."
L["Icon Display Limit"] = "Limite d'icônes affichées"
L["MAX_ICONS_DESC"] = "Limiter le nombre d'icônes affichées sur cette barre. 0 = illimité."
L["Grow Direction"] = "Direction de croissance"
L["GROW_DIR_DESC"] = "Direction dans laquelle les icônes sont ajoutées."
L["Right (rows stack down)"] = "Droite (lignes vers le bas)"
L["Left (rows stack down)"] = "Gauche (lignes vers le bas)"
L["Down (columns stack right)"] = "Bas (colonnes vers la droite)"
L["Up (columns stack right)"] = "Haut (colonnes vers la droite)"
L["Show Cooldown Text"] = "Afficher le texte de cooldown"
L["SHOW_CD_TEXT_DESC"] = "Afficher le temps restant en texte sur les icônes pendant le cooldown."
L["Show Icon Border"] = "Afficher les bordures"
L["SHOW_BORDER_DESC"] = "Afficher les bordures colorées par classe autour des icônes."

------------------------------------------------------------------------
-- Arena Visibility
------------------------------------------------------------------------
L["Arena Visibility"] = "Visibilité en arène"
L["Visibility Mode"] = "Mode de visibilité"
L["VISIBILITY_MODE_DESC"] = "Choisissez pour quels adversaires d'arène cette barre suit les sorts."
L["All Enemies"] = "Tous les ennemis"
L["Arena 1 Only"] = "Arène 1 uniquement"
L["Arena 2 Only"] = "Arène 2 uniquement"
L["Arena 3 Only"] = "Arène 3 uniquement"
L["Duplicate Same Spec/Class"] = "Dupliquer même spé/classe"
L["DUPLICATE_DESC"] = "Afficher une seconde icône lorsque plusieurs adversaires partagent la même spécialisation ou classe."
L["ARENA_VIS_NOTE"] = "|cff888888Note :|r Quand 'Tous les ennemis' est sélectionné, les sorts de tous les adversaires détectés sont affichés. Sélectionner un slot d'arène spécifique filtre uniquement cet adversaire."

------------------------------------------------------------------------
-- Bar Actions
------------------------------------------------------------------------
L["Actions"] = "Actions"
L["Reset Bar Cooldowns"] = "Réinitialiser les cooldowns"
L["RESET_BAR_CD_DESC"] = "Réinitialiser tous les cooldowns actifs sur cette barre."
L["COOLDOWNS_RESET_BAR"] = "Cooldowns réinitialisés pour la barre : %s"
L["Reset Position"] = "Réinitialiser la position"
L["RESET_POS_DESC"] = "Remettre cette barre au centre de l'écran."
L["Delete This Bar"] = "Supprimer cette barre"
L["DELETE_BAR_DESC"] = "Supprimer définitivement cette barre et tous ses paramètres."
L["DELETE_BAR_CONFIRM"] = "Êtes-vous sûr de vouloir supprimer la barre '%s' ?\nCette action est irréversible."

------------------------------------------------------------------------
-- Spells
------------------------------------------------------------------------
L["Spells"] = "Sorts"
L["Enable Default"] = "Activer par défaut"
L["Disable All"] = "Tout désactiver"
L["All Specs"] = "Toutes les spé"
L["Multiple Specs"] = "Plusieurs spé"
L["Unknown Spec"] = "Spé inconnue"

------------------------------------------------------------------------
-- Customize Tab
------------------------------------------------------------------------
L["Cooldown Overrides"] = "Modification des cooldowns"
L["CD_OVERRIDE_DESC"] = "Modifier la durée de cooldown par défaut de n'importe quel sort de MajorCooldowns.\nLes modifications s'appliquent à toutes les barres."
L["Custom Spells"] = "Sorts personnalisés"
L["CUSTOM_SPELLS_DESC"] = "Ajoutez vos propres sorts personnalisés qui ne sont pas inclus dans MajorCooldowns.\nLes sorts personnalisés peuvent être assignés à n'importe quelle barre."
L["Spell ID"] = "ID du sort"
L["SPELL_ID_DESC"] = "L'identifiant numérique du sort depuis Wowhead ou l'infobulle en jeu."
L["Cooldown (seconds)"] = "Cooldown (secondes)"
L["CD_SECONDS_DESC"] = "Durée du cooldown en secondes."
L["Class"] = "Classe"
L["CLASS_DESC"] = "La classe à laquelle ce sort appartient."
L["Specialization"] = "Spécialisation"
L["SPEC_DESC"] = "La spécialisation à laquelle ce sort appartient, ou Toutes les spé pour les talents de classe."
L["Class Ability"] = "Talent de classe"
L["Category"] = "Catégorie"
L["CATEGORY_DESC"] = "La catégorie de ce sort."
L["Add Custom Spell"] = "Ajouter un sort personnalisé"
L["Remove"] = "Supprimer"
L["REMOVE_CUSTOM_CONFIRM"] = "Supprimer le sort personnalisé '%s' ?"
L["CUSTOM_ADDED"] = "Sort personnalisé '|cff00ff00%s|r' (ID : %d) ajouté."
L["CUSTOM_REMOVED"] = "Sort personnalisé '|cffff0000%s|r' supprimé."
L["CUSTOM_INVALID_ID"] = "ID de sort invalide. Veuillez entrer un nombre valide."
L["CUSTOM_ALREADY_EXISTS"] = "Un sort personnalisé avec cet ID existe déjà."
L["No custom spells added yet."] = "Aucun sort personnalisé ajouté."
L["Default Duration"] = "Durée par défaut"
L["Override Duration"] = "Durée modifiée"
L["OVERRIDE_DURATION_DESC"] = "Durée de cooldown modifiée en secondes. 0 = utiliser la durée par défaut."
L["Reset Override"] = "Réinitialiser"
L["Select a class..."] = "Sélectionner une classe..."

------------------------------------------------------------------------
-- Tooltips
------------------------------------------------------------------------
L["Cooldown: %ds"] = "Cooldown : %ds"
L["Category: %s"] = "Catégorie : %s"
L["Charges: %d / %d"] = "Charges : %d / %d"
L["Left-click: Start cooldown"] = "|cff00ff00Clic gauche :|r Démarrer le cooldown"
L["Right-click: Reset cooldown"] = "|cffff0000Clic droit :|r Réinitialiser le cooldown"
L["Click and drag to move"] = "Cliquer et glisser pour déplacer"

------------------------------------------------------------------------
-- Lock Messages
------------------------------------------------------------------------
L["Bars locked."] = "Barres |cffff0000verrouillées|r."
L["Bars unlocked."] = "Barres |cff00ff00déverrouillées|r."
