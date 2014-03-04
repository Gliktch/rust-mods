PLUGIN.Title = "Mod Information"
PLUGIN.Author = "Gliktch"
PLUGIN.Version = "0.3"
PLUGIN.Description = "Displays a list of mods running on the server, and their basic settings."

function PLUGIN:Init()
    print("Loading Mod Information...")
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

-- to do

end

function PLUGIN:ListMods( netuser, args )
    -- Enumerate installed mods and fetch versions
    -- Completely not tested yet, likely not working
    local i = 0
    for i, #plugins.Count
        print(plugins.Find(i).Title .. " v" .. plugins.Find(i).Version .. " (" .. tostring(plugins.Find(i)) .. ".lua)")
    end
end

function PLUGIN:CheckAll( netuser, args, frominit )
    local i = 0
    for i, #plugins.Count
        UpdateCheck( tostring(plugins.Find(i)), netuser, frominit )
    end
end

function toboolean(var)
  return not not var
end

function round(num, dec)
  local pow = 10^(dec or 0)
  return math.floor(num * pow + 0.5) / pow
end

function PLUGIN:cmdMods( netuser, args )

-- to do

end
