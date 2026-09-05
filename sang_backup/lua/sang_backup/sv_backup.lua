--[[-------------------------------------------------------------------------
    Sang et Nuit — Backup : sauvegarde périodique + backup SQL (sv.db)

    Le fichier SQLite (garrysmod/sv.db) n'est PAS accessible via le module
    `file` (bac à sable data/). On ne peut donc pas le copier tel quel : on
    DUMPE les tables « Sang » en JSON dans garrysmod/data/sang/backups/.

    - Sauvegarde AUTOMATIQUE toutes les C.Interval secondes.
    - Sauvegarde à l'extinction du serveur (hook ShutDown).
    - Rotation : on garde les C.KeepBackups plus récents.
    - Avant chaque dump : hook "Sang_SaveAll" (les addons vident leur cache
      mémoire vers la SQL — ex. niveaux des joueurs en ligne).
    - Commandes console :
        sang_backup_now              -> sauvegarde immédiate
        sang_backup_list             -> liste les backups
        sang_backup_restore <fichier>-> restaure un backup (DANGEREUX)
---------------------------------------------------------------------------]]

SBK = SBK or {}
local C = SBK.Config

----------------------------------------------------------------------
-- Découverte des tables « Sang »
----------------------------------------------------------------------
function SBK.DiscoverTables()
    local rows = sql.Query("SELECT name FROM sqlite_master WHERE type = 'table';")
    local out = {}
    if istable(rows) then
        for _, r in ipairs(rows) do
            local name = r.name
            for _, pref in ipairs(C.TablePrefixes) do
                if string.sub(name, 1, #pref) == pref then
                    out[#out + 1] = name
                    break
                end
            end
        end
    end
    table.sort(out)
    return out
end

----------------------------------------------------------------------
-- Rotation des fichiers
----------------------------------------------------------------------
local function rotate()
    local files = select(1, file.Find(C.Dir .. "/backup_*.json", "DATA"))
    if not istable(files) then return end
    table.sort(files) -- l'horodatage dans le nom trie chronologiquement
    local excess = #files - math.max(1, C.KeepBackups)
    for i = 1, excess do
        file.Delete(C.Dir .. "/" .. files[i])
    end
end

----------------------------------------------------------------------
-- Dump (sauvegarde)
----------------------------------------------------------------------
function SBK.Dump(reason)
    -- 1) Laisse les addons flusher leur état mémoire vers la SQL.
    hook.Run("Sang_SaveAll")

    -- 2) Récupère toutes les tables Sang.
    local tables = SBK.DiscoverTables()
    local data = {
        version = 1,
        time    = os.time(),
        date    = os.date("%Y-%m-%d %H:%M:%S"),
        reason  = reason or "manuel",
        tables  = {},
        counts  = {},
    }
    local totalRows = 0
    for _, t in ipairs(tables) do
        local rows = sql.Query("SELECT * FROM " .. t .. ";")
        rows = istable(rows) and rows or {}
        data.tables[t] = rows
        data.counts[t] = #rows
        totalRows = totalRows + #rows
    end

    -- 3) Écrit le fichier JSON horodaté.
    if not file.IsDir(C.Dir, "DATA") then file.CreateDir(C.Dir) end
    local stamp = os.date("%Y-%m-%d_%H-%M-%S")
    local fname = C.Dir .. "/backup_" .. stamp .. ".json"
    file.Write(fname, util.TableToJSON(data, true))

    rotate()

    MsgN(("[Sang Backup] Sauvegarde (%s) : %d table(s), %d ligne(s) -> data/%s")
        :format(data.reason, #tables, totalRows, fname))
    return fname, #tables, totalRows
end

----------------------------------------------------------------------
-- Liste des backups
----------------------------------------------------------------------
function SBK.List()
    local files = select(1, file.Find(C.Dir .. "/backup_*.json", "DATA"))
    if not istable(files) then return {} end
    table.sort(files)
    return files
end

----------------------------------------------------------------------
-- Restauration (DANGEREUX : écrase les tables Sang)
----------------------------------------------------------------------
function SBK.Restore(name)
    -- Sécurise le nom (pas de traversée de dossier).
    name = string.GetFileFromFilename(tostring(name or ""))
    if name == "" then return false, "nom vide" end
    local path = C.Dir .. "/" .. name
    if not file.Exists(path, "DATA") then return false, "fichier introuvable" end

    local raw = file.Read(path, "DATA")
    local data = raw and util.JSONToTable(raw)
    if not (istable(data) and istable(data.tables)) then return false, "JSON invalide" end

    local nTables, nRows = 0, 0
    sql.Begin()
    for tname, rows in pairs(data.tables) do
        if sql.TableExists(tname) then
            sql.Query("DELETE FROM " .. tname .. ";")
            if istable(rows) then
                for _, row in ipairs(rows) do
                    local cols, vals = {}, {}
                    for k, v in pairs(row) do
                        cols[#cols + 1] = k
                        vals[#vals + 1] = sql.SQLStr(v)
                    end
                    if #cols > 0 then
                        sql.Query("INSERT INTO " .. tname .. " (" .. table.concat(cols, ", ")
                            .. ") VALUES (" .. table.concat(vals, ", ") .. ");")
                        nRows = nRows + 1
                    end
                end
            end
            nTables = nTables + 1
        end
    end
    sql.Commit()

    MsgN(("[Sang Backup] Restauration de %s : %d table(s), %d ligne(s). "
        .. "Un changement de map / une reconnexion est conseillé.")
        :format(name, nTables, nRows))
    return true, nTables .. " table(s), " .. nRows .. " ligne(s)"
end

----------------------------------------------------------------------
-- Sauvegarde périodique + à l'extinction
----------------------------------------------------------------------
timer.Create("SBK_AutoSave", math.max(60, C.Interval), 0, function()
    SBK.Dump("auto")
end)

hook.Add("ShutDown", "SBK_ShutdownSave", function()
    SBK.Dump("arret_serveur")
end)

----------------------------------------------------------------------
-- Commandes console
----------------------------------------------------------------------
local function canManage(ply)
    -- Console serveur : autorisé. Joueur : superadmin ou admin Sang.
    if not IsValid(ply) then return true end
    if ply:IsSuperAdmin() then return true end
    return BLOOD and BLOOD.IsAdmin and BLOOD.IsAdmin(ply)
end

local function reply(ply, msg)
    if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, msg) else print(msg) end
end

concommand.Add("sang_backup_now", function(ply)
    if not canManage(ply) then return end
    local fname, nt, nr = SBK.Dump("manuel")
    reply(ply, "[Sang Backup] Sauvegarde faite : data/" .. fname .. " (" .. nt .. " tables, " .. nr .. " lignes)")
end)

concommand.Add("sang_backup_list", function(ply)
    if not canManage(ply) then return end
    local files = SBK.List()
    reply(ply, "[Sang Backup] " .. #files .. " backup(s) :")
    for _, f in ipairs(files) do reply(ply, "   " .. f) end
    if #files == 0 then reply(ply, "   (aucun)") end
end)

concommand.Add("sang_backup_restore", function(ply, _, args)
    -- Restauration réservée à la CONSOLE SERVEUR ou aux SUPERADMINS.
    if IsValid(ply) and not ply:IsSuperAdmin() then
        reply(ply, "[Sang Backup] Restauration réservée à la console serveur / superadmin.")
        return
    end
    local ok, info = SBK.Restore(args[1])
    if ok then
        reply(ply, "[Sang Backup] Restauré (" .. info .. "). Change de map ou reconnecte-toi.")
    else
        reply(ply, "[Sang Backup] Échec : " .. tostring(info))
    end
end, nil, "Restaure un backup Sang (console/superadmin). Usage: sang_backup_restore <fichier.json>")

MsgN("[Sang Backup] Prêt — sauvegarde auto toutes les " .. math.floor(math.max(60, C.Interval) / 60) .. " min.")
