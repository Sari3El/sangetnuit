# Griffe de l'Originel — SWEP (référence)

`weapon_griffe_originel.lua` est un **sabre wiltOS** (ALCS / AdvSWL) dérivé de la
base « personal ».

> ⚠️ **Copie de référence uniquement.** Ce dossier n'est **pas** un addon à monter.
> Le fichier est volontairement placé **hors** d'un dossier `lua/` pour que GMod ne
> le charge **pas** (sinon le SWEP serait défini deux fois).

## Où le placer

À copier dans l'addon wiltOS (wos origin) :

```
wos-sentinel-orig/lua/weapons/weapon_griffe_originel.lua
```

## Caractéristiques

- Base : `wos_adv_single_lightsaber_base` (sabre simple, non dual)
- `SWEP.PersonalLightsaber = false` — sabre **fixe** (pas lié au perso wiltOS)
- `SWEP.UseForms = { ["Agile"] = { 1, 2, 3 } }` — force les **3 stances de la forme Agile** (indispensable sur un sabre fixe, sinon aucune forme)
- `SWEP.ForcePowerList = { "Force Leap" }` — pouvoirs à définir plus tard
- Modèles **placeholder** (repris du sabre personnel) — les vraies griffes viendront après
- `SWEP.Spawnable = true` + `SWEP.AdminOnly = true` — spawn réservé au staff

Les **stats / hilt / couleur / dégâts** se règlent dans le fichier wiltOS :
`wos/advswl/config/crafting/sh_craftwos.lua`.

## Attribution au job

Le joueur du job **« L'Originel »** (`hybride_15`) reçoit l'arme via le loadout —
géré côté serveur par toi-même (pas dans `sang_jobs`).
