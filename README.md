# Sang et Nuit — Système de personnages & de « Sang » (races)

Addon **Garry's Mod** (Lua) : système de personnages multi-slots, races
(« sang ») avec multiplicateurs de stats, et reroll payant en monnaie custom.
Conçu pour **DarkRP** mais **indépendant** (fonctionne aussi en Sandbox pour
tester), car les crédits de reroll sont une monnaie dédiée dissociée de l'or
DarkRP.

> 📄 **Pour installer et tester en solo, lis [`INSTALLATION.txt`](INSTALLATION.txt).**
> Il explique où ranger chaque fichier et comment lancer un serveur écoute local.

## Ce qui est implémenté

- **Personnages** : 4 slots (3 gratuits + 1 payant), chacun avec sa propre race
  sauvegardée. Un perso spawn toujours en Humain.
- **Races (15)** : tirage pondéré serveur-side sur `math.random(1,10000)`
  (Sorcier = 1/1000 exact). Multiplicateurs PV/vitesse, réduction/bonus de
  dégâts, esquive, régénération, résistance au feu, discrétion.
- **Reroll** : payant en crédits (débit **avant** tirage, pas de remboursement),
  retour Humain **gratuit**. Cooldown anti-spam. 100 % serveur-side.
- **Persistance SQL** : crédits par joueur (SteamID64) + slots (nom + race).
  Fonctionne hors-ligne (crédits/race modifiables sur un joueur déconnecté).
- **Menu admin `!origines`** : whitelist SteamID64 vérifiée **serveur-side à
  chaque action**, donner des crédits, définir une race sur un slot, logs.
- **UI joueur `!perso`** : slots, reroll (coût affiché), retour Humain, race
  actuelle.

## Règles respectées

- Tirage **serveur-side** uniquement ; **débit avant tirage** ; pas de remboursement.
- **Saut jamais modifié** ; vitesse de base **×0.9 pour tous** ; modificateur
  de race **plafonné à ±0.2** (exception vitesse Homme-aigle +0.25).
- Pouvoirs = **SWEP donnée au spawn** (jamais de touche), retirée au changement
  de race.

## Hors périmètre (à ajouter plus tard)

Les **3 SWEP de pouvoir** ne sont pas fournies : Sang-dragon (« Crachat de
feu »), Homme-aigle (« Vol »), et le **module Sorcier** (mana + sorts). Le
cadre de distribution des SWEP au spawn est déjà en place ; les classes sont
déclarées dans la config et ignorées tant que la SWEP n'existe pas.

## Structure

```
lua/autorun/sang_init.lua      Chargeur
lua/sang/config/sh_config.lua  ← Config / équilibrage / whitelist
lua/sang/core/                 Partagé : util, index races, net strings
lua/sang/server/               Logique serveur : SQL, tirage, stats, admin
lua/sang/client/               Interfaces Derma (menu joueur + admin)
```

Commandes : `!perso` (menu joueur) · `!origines` (menu admin).
