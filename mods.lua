PLUGIN.Title = "Mods Information"
PLUGIN.Author = "Gliktch"
PLUGIN.Version = "0.3"
PLUGIN.Description = "Displays a list of mods running on the server, and their basic settings."

function PLUGIN:Init()
  print("Loading Mods Information mod...")
  self:AddChatCommand( "mods", self.cmdMods )
  self:CollectValues()
  if (modstimer) then modstimer:Destroy() end
  modstimer = timer.Repeat( 15, self.CollectValues )
end

function PLUGIN:UpdateCheck( modname, netuser, frominit )
    -- Check if Resource ID is set
    if (modname.ResourceID) then
        -- Get latest version from URL
        local url = "http://wulf.im/oxide/" .. modname.ResourceID
        --local url = "http://forum.rustoxide.com/api.php?action=getResource&value=" .. self.ResourceID
        local request = webrequest.Send(url, function(code, response)
            -- Check for HTTP success
            if (code == 200) then
                -- Check if being called from server start
                if (frominit) then
                    -- Check for valid latest version
                    if (modname.Version < response) then
                        error("Outdated plugin \"" .. modname.Title .. "\" (filename " .. modname .. ".lua)! Installed: v" .. modname.Version .. ", Latest: v" .. response)
                        error("Visit http://forum.rustoxide.com/resources/" .. modname.ResourceID .. "/ to download the latest version!")
                        assert(modname .. "UpdateAlertTimer") = timer.Once( 30, function() Rust.BroadcastChat("Alert: \"" .. modname.Title .. "\" (filename " .. modname .. ".lua) has an update available, from v" .. modname.Version .. " to v" .. response .. ".") end )
                    else
                        if self.Config.verboseUpdateChecks
                            print("Mod \"" .. modname.Title .. "\" v" .. modname.Version .. " (filename " .. modname .. ".lua) has been verified as up to date (latest version reported as v" .. response .. ").")
                    end
                -- If being called from within the /mods command, return the information internally
                else
                    return response
                end
            else
                updatefailed = true
            end
        end)
        if ((not request) or (updatefailed)) then
            errmsg = "Alert: Update Check Failed for \"" .. tostring(modname.Title) .. "\" (filename " .. tostring(modname) .. ".lua) v" .. tostring(modname.Version) .. "."
            -- Broadcast error if from server start, or send to user if from command
            if frominit and assert(modname .. "UpdateFailTimer") = timer.Repeat( 60, 3, function() Rust.BroadcastChat( errmsg ) end ) or Rust.SendChatToUser( netuser, errmsg )
            -- Print to server log if not successful
           error("Update check failed for mod " .. tostring(modname) .. " with ID " .. tostring(modname.ResourceID) .. "!")
        end
    end
end

function PLUGIN:CollectValues()

	flags_plugin = plugins.Find("flags")
	if (not flags_plugin) then

		return
	end

 -- Main server info
  hostname = Rust.server.hostname
  hostip   = Rust.server.ip
  hostport = Rust.server.port

 -- Most common settings
  sleep    = Rust.sleepers.on
  pvp      = Rust.server.pvp
  craftin  = Rust.crafting.instant
--  craftin  = assert(tostring(Rust.crafting.instant) or function() if Rust.crafting.instant == false then return "false" else return "unset" end end

-- Further useful settings
  maxplay  = Rust.server.maxplayers
  airmin   = Rust.airdrop.min_players
  craftts  = Rust.crafting.timescale
  craftws  = Rust.crafting.workbench_speed
  falldmg  = Rust.falldamage.enabled
  daydur   = Rust.env.daylength
  nightdur = Rust.env.nightlength
  decaysec = Rust.decay.deploy_maxhealth_sec
  durmult  = Rust.conditionloss.damagemultiplier
  durmulta = Rust.conditionloss.armorhealthmult

-- Less common settings
  voicedis = Rust.voice.distance
  ctimeout = Rust.server.clienttimeout
  srvgroup = Rust.server.steamgroup
  tickrate = Rust.decay.decaytickrate
  fallminv = Rust.falldamage.min_vel
  fallmaxv = Rust.falldamage.max_vel
  legstime = Rust.falldamage.injury_length
  locktime = Rust.player.backpackLockTime
  autotime = Rust.save.autosavetime
end

function toboolean(var)
  return not not var
end

function round(num, dec)
  local pow = 10^(dec or 0)
  return math.floor(num * pow + 0.5) / pow
end

function PLUGIN:cmdMods( netuser, args )

local decaytext = ""
if decaysec == 43200 then
  decaytext = "at the standard rate."
elseif decaysec < 43200 then
  decaytext = "FASTER, about " .. round(43200 / decaysec, 2) .. "x the normal rate."
elseif decaysec > 43200 then
  decaytext = "SLOWER, about 1/" .. round(decaysec / 43200, 2) .. "th the normal rate."
end

  rust.SendChatToUser( netuser, "Server: " .. hostname .. " (" .. tostring( #rust.GetAllNetUsers() ) .. "/" .. maxplay .. ")")
  rust.SendChatToUser( netuser, "To connect manually, you can use use net.connect " .. hostip .. ":" .. hostport .. " in the F1 console.")
  rust.SendChatToUser( netuser, "Sleepers are " .. (toboolean(sleep) and "ON" or "OFF") .. ", PVP is " .. (toboolean(pvp) and "ON" or "OFF") .. ", Fall Damage is " .. (toboolean(falldmg) and "ON" or "OFF") .. ", and Decay is " .. decaytext)
  rust.SendChatToUser( netuser, "Instant crafting is " .. (toboolean(craftin) and "ON" or "OFF, but the Crafting Timescale is " .. craftts .. " and reduced by " .. craftws .. "x when at a Workbench."))
end
