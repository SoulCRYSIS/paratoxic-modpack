local function modify_game_start_scripts()
  local freeplay = remote.interfaces.freeplay
  if freeplay then
    remote.call("freeplay", "set_skip_intro", true)
    if freeplay.set_disable_crashsite then
      remote.call("freeplay", "set_disable_crashsite", true)
    end
  end
end

local function skip_rubia_cutscene()
  local tech = game.forces["player"].technologies["planetslib-rubia-cargo-drops"]
  if tech and not tech.researched then
    tech.researched = true
  end
end

local function create_self()
  local force = game.forces["player"]
  local platform = force.create_space_platform({
    name = "The Motherframe",
    planet = "rubia",
    starter_pack =
    "space-platform-starter-pack"
  })

  platform.apply_starter_pack()
  storage.platform = platform
end

local function give_starting_items()
  if storage.platform.hub then
    storage.platform.hub.insert({ name = "asteroid-collector", count = 2 })
    storage.platform.hub.insert({ name = "inserter", count = 10 })
    storage.platform.hub.insert({ name = "heat-pipe", count = 50 })
    storage.platform.hub.insert({ name = "space-platform-foundation", count = 490 })
  end
end

local function create_permission_group()
  game.permissions.create_group("players")
end

local function refresh_data_storage()
  if not storage.players then
    storage.players = {}
  end
  if game and game.players then
    for _, player in pairs(game.players) do
      if storage.players[player.index] and not storage.players[player.index].probes then
        storage.players[player.index].probes = {}
      end
    end
  end
  if not storage.supercomputer then
    storage.supercomputer = {}
  end
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
  storage.pending_remote_entries = nil
end

script.on_init(function()
  modify_game_start_scripts()
  refresh_data_storage()
  game.forces["player"].technologies["planet-discovery-rubia"].researched = true
  create_self()
  give_starting_items()
  create_permission_group()
  skip_rubia_cutscene()
end)

script.on_configuration_changed(function()
  refresh_data_storage()
  skip_rubia_cutscene()
end)

script.on_event(defines.events.on_player_created, function(e)
  local player = game.players[e.player_index]
  storage.players[player.index] = { probes = {} }
  player.teleport({ x = 0, y = 0 }, storage.platform.surface.name)
  player.enter_space_platform(storage.platform)
  if e.player_index == 1 then
    player.request_translation({ "self.self-platform-name" })
  end

  local group_name = "player_" .. player.index
  local group = game.permissions.get_group(group_name)
  if not group then
    group = game.permissions.create_group(group_name)
  end
  group.add_player(player)
  group.set_allows_action(defines.input_action.land_at_planet, true)
  group.set_allows_action(defines.input_action.add_permission_group, false)
  group.set_allows_action(defines.input_action.edit_permission_group, false)
  group.set_allows_action(defines.input_action.delete_permission_group, false)
end)
