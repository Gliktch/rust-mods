PLUGIN.Title = "Mod Information"
PLUGIN.Author = "Gliktch"
PLUGIN.Version = "0.5.4"
PLUGIN.Description = "Displays a list of mods running on the server, their versions and basic settings."

function PLUGIN:Init()
    print("Loading " .. self.Title .. " v" .. self.Version .. ", by " .. self.Author .. "...")
    ModsDataFile = util.GetDatafile( "modsdata" )
    local txt = ModsDataFile:GetText()
    if (txt ~= "") then
        ModsData = json.decode( txt )
    else
        ModsData = {}
        ModsDataFile:SetText( json.encode( ModsData ) )
        ModsDataFile:Save()
    end
    self:AddChatCommand( "mods", self.cmdMods )
end

function PLUGIN:PostInit()
    if (modstimer) then modstimer:Destroy() end
    modstimer = timer.Once( 3, function() self.CollectValues() end )
    -- modstimer = timer.Repeat( 15, self.CollectValues )
    -- self:CollectValues()
    -- self:CheckAll()
end

function PLUGIN:CollectValues()
    local sincelast = self:TimeCalc(self:round((System.DateTime.Now.Ticks - 621355968000000000) / 10000000) - ModsData.LastUpdated)
    print("Mods last checked " .. tostring(sincelast) .. " ago.")
    typesystem.LoadNamespace( "Oxide" )
    local sgetter, ssetter = typesystem.GetField( Oxide.Main, "singleton", bf.private_static )
    local oxidemain = sgetter( nil )
    local pluginsystem = oxidemain.PluginManager
    local en = pluginsystem:GetPlugins():GetEnumerator()
    local lastmod = "xyz"
    local currentmod = ""
    local counter = 0
    ModsData.mods = {}
    en:MoveNext()
    while ((en.Current) and (lastmod ~= currentmod)) do
        counter = counter + 1
        ModsData.mods[ counter ] = {}
        ModsData.mods[ counter ].Name = en.Current.Name
        ModsData.mods[ counter ].Title = en.Current.Title
        ModsData.mods[ counter ].Version = en.Current.Version
        ModsData.mods[ counter ].ResourceID = 
            en.Current.Table["ResourceID"] or
            en.Current.Table["RID"] or
            en.Current.Table["ResourceId"]
        ModsData.mods[ counter ].ShortFilename = en.Current.ShortFilename
        ModsData.mods[ counter ].Filename = en.Current.Filename
        lastmod = en.Current.Name
        en:MoveNext()
        currentmod = en.Current.Name
    end
    ModsData.LastUpdated = self:round((System.DateTime.Now.Ticks - 621355968000000000) / 10000000)
    ModsData.LastUpdatedText = tostring(System.DateTime.Now)
    local ModsJson = json.encode( ModsData )
    ModsDataFile:SetText( ModsJson )
    ModsDataFile:Save()
end

function PLUGIN:UpdateCheck( modtable, netuser, frominit )
    -- Check if Resource ID is set
    if (modtableResourceID) then
        -- Get latest version from URL
        local url = "http://wulf.im/oxide/" .. modtable.ResourceID
        local request = webrequest.Send(url, function(code, response)
            -- Check for HTTP success
            if (code == 200) then
                -- Check if being called from server start
                if (frominit) then
                    -- Check for valid latest version
                    if (modtable.Version < response) then
                        error("Outdated plugin \"" .. modtable.Title .. "\" (filename " .. modtable.ShortFilename .. ")! Installed: v" .. modtable.Version .. ", Latest: v" .. response)
                        error("Visit http://forum.rustoxide.com/resources/" .. modtable.ResourceID .. "/ to download the latest version!")
                        blahtimer = timer.Once( 30, function() Rust.BroadcastChat("Alert: \"" .. modtable.Title .. "\" (filename " .. modtable.ShortFilename .. ") has an update available, from v" .. modtable.Version .. " to v" .. response .. ".") end )
                    else
                        if self.Config.verboseUpdateChecks then
                            print("Mod \"" .. modtable.Title .. "\" v" .. modtable.Version .. " (filename " .. modtable.ShortFilename .. ") has been verified as up to date (latest version reported as v" .. response .. ").")
                        end
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
            errmsg = "Alert: Update Check Failed for \"" .. tostring(modtable.Title) .. "\" (filename " .. tostring(modtable.ShortFilename) .. ") v" .. tostring(modtable.Version) .. "."
            -- Broadcast error if from server start, or send to user if from command
            if frominit then
                ModUpdateFailTimer = timer.Repeat( 60, 3, function() Rust.BroadcastChat( errmsg ) end )
            else
               Rust.SendChatToUser( netuser, errmsg )
            end
            -- Print to server log if not successful
            error("Update check failed for mod " .. tostring(modtable.Title) .. " with ID " .. tostring(modtable.ResourceID) .. "!")
        end
    end
end

function PLUGIN:CheckAll( netuser, args, frominit )
    for i = 0, #self.ModsData.mods do
        self:UpdateCheck( self.ModsData.mods[i], netuser, true )
    end
end

function PLUGIN:TimeCalc(tsecs)
  if tsecs == 0 then
    return "just now"
  elseif tsecs < 60 then
    return "less than a minute"
  else
    local days  = math.floor(tsecs/86400)
    local hours = math.floor(tsecs/3600 - (days*24))
    local mins  = math.floor(tsecs/60 - (days*1440) - (hours*60))
    -- dont think we need this kind of resolution
    -- local secs  = math.floor(tsecs - (days*86400) - (hours*3600) - (mins*60));
    local timestring = (
        days  and (days  > 1 and days  .. " days"    or days  .. " day" ((hours or mins) and " and ")) ..
        hours and (hours > 1 and hours .. " hours"   or hours .. " hour" (mins and " and ")) ..
        mins  and (mins  > 1 and mins  .. " minutes" or mins  .. " minute")
        )
        -- secs  and (secs  > 1) and secs  .. " seconds" or secs .. " second")
    return timestring
  end
end

function PLUGIN:toboolean(var)
  return not not var
end

function PLUGIN:round(num, dec)
  local pow = 10^(dec or 0)
  return math.floor(num * pow + 0.5) / pow
end

function PLUGIN:cmdMods( netuser, args )
-- plenty more to do
  if args[1] then
    for i = 0, #self.ModsData.mods do
      if self.ModsData.mods[i].Name == args[1] then
          self:UpdateCheck(self.ModsData.mods[i], netuser, false)
      end
    end
  else
    Rust.SendChatToUser( netuser, "You need to specify a mod name, or put \"all\"" )
  end
end
