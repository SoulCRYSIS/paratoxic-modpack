local gameplay = require("logics.gameplay")

local function modify_game_start_scripts() --apparently, the cutscene prevents the player from being teleported.
  local freeplay = remote.interfaces.freeplay
  if freeplay then
    remote.call("freeplay", "set_skip_intro", true)          --No intro message
    if freeplay.set_disable_crashsite then
      remote.call("freeplay", "set_disable_crashsite", true) --No crashsite cutscene nor ship.
    end
  end
end

local function refresh_data_storage() --This should allow new storages to be added without the creation of a new world
  if not storage.players then
    storage.players = {}
  end
  if not storage.supercomputer then
    storage.supercomputer = {}
  end
  -- if not storage.story then
  --   storage.story = {}
  -- end
  -- if not storage.story.tech_progress then
  --   storage.story.tech_progress = 0
  -- end
  -- if not storage.story.handlers then
  --   storage.story.handlers = {}
  -- end
  if not storage.worms then
    storage.worms = {}
  end
  if not storage.worms.recent_launch_count then
    storage.worms.recent_launch_count = 0
  end
  if not storage.worms.active_worms then
    storage.worms.active_worms = {}
  end
  if not storage.gameplay then
    storage.gameplay = {}
  end
  -- if not storage.story.self_version then
  --   story.get_self_version()
  -- end
end

-- function deal_with_stupid_handlers()
--   if settings.global["start-as-SELF"].value then --these scripts shouldnt run if we dont have self.
--     if not storage.story.handlers.no_more_softlock then
--       script.on_nth_tick(256,                    --be aware this gets unregistered later
--         function()
--           gameplay.softlock_detection()
--         end
--       )
--     end
--     if not storage.story.handlers.no_more_self_control then
--       script.on_nth_tick(1,
--         function()
--           gameplay.self_control()
--         end
--       )
--     end
--   end
-- end

function set_starting_flags()
  -- if not settings.global["start-as-SELF"].value then
  -- storage.story.handlers.no_more_self_control = true
  -- storage.story.handlers.no_more_softlock = true
  -- end
end

script.on_init(function(e)    --Code shamelessly plagerised from Platformer by Corlin and Xiroc
  modify_game_start_scripts() --Necessary for player to be teleported and imprisoned
  refresh_data_storage()
  set_starting_flags()        --sets certain flags based on starting settings
  -- deal_with_stupid_handlers()

  gameplay.create_self()   --Create starting space platform
  gameplay.give_starting_items()
  gameplay.create_permission_group()
end)

script.on_configuration_changed(function()
  refresh_data_storage()
end)

-- script.on_load(function()
--   deal_with_stupid_handlers()
-- end)

--Upon player joins
script.on_event(defines.events.on_player_created, function(e)
  local player = game.players[e.player_index]
  storage.players[player.index] = {} --initialise player storage
  player.teleport({ x = 0, y = 0 }, storage.platform.surface.name)
  player.enter_space_platform(storage.platform)
  if e.player_index == 1 then
    player.request_translation({ "self.self-platform-name" })
  end
  
  local group = game.permissions.get_group("players")
  if group then
    group.add_player(player)
  end
end)
