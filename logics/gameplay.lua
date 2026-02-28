local gameplay = {}

function gameplay.create_self()
  local force = game.forces["player"]
  local platform = force.create_space_platform({
    name = "SELF",
    planet = "rubia",
    starter_pack =
    "space-platform-starter-pack"
  })

  platform.apply_starter_pack()
  storage.platform = platform
end

function gameplay.give_starting_items()
  if storage.platform.hub then
    storage.platform.hub.insert({ name = "asteroid-collector", count = 2 })
    storage.platform.hub.insert({ name = "inserter", count = 10 })
    storage.platform.hub.insert({ name = "heat-pipe", count = 50 })
    storage.platform.hub.insert({ name = "space-platform-foundation", count = 490 })
  end
end

function gameplay.create_permission_group()
  game.permissions.create_group("players")
end

function gameplay.goto_platform(player)
  player.teleport({ x = 0, y = 0 }, storage.platform.surface.name)
  player.enter_space_platform(storage.platform)
end

function gameplay.on_respawn(event)
  if not storage.platform.valid then
    gameplay.create_self()
    local platform = storage.platform
    local hub = platform.hub
    gameplay.give_starting_items()
    hub.insert({ name = "pistol", count = 2250831, quality = "legendary" }) --consolation prize
    platform.distance = 0.0002
    platform.speed = 1
  end
  local player = game.players[event.player_index]
  gameplay.goto_platform(player)
end

return gameplay
