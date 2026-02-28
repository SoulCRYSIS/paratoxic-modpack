-- Probe deployment system: player character stays on mainframe, probes controlled remotely
local gameplay = require("logics.gameplay")

local PROBE_NAME = "paratoxic-probe"
local SURFACE_SWAP_SHORTCUT = "paratoxic-surface-swap"

local PROBE_EQUIPMENT = {
  { name = "personal-roboport-equipment", count = 1 },
  { name = "fusion-reactor-equipment", count = 1 }
}

local function get_power_equipment()
  if prototypes.item["fusion-reactor-equipment"] then
    return "fusion-reactor-equipment"
  end
  if prototypes.item["fission-reactor-equipment"] then
    return "fission-reactor-equipment"
  end
  return "solar-panel-equipment"
end

local function ensure_player_storage(player_index)
  if not storage.players[player_index] then
    storage.players[player_index] = {}
  end
  if not storage.players[player_index].probes then
    storage.players[player_index].probes = {}
  end
end

local function equip_probe(probe)
  local grid = probe.grid
  if not grid then return end
  local power = get_power_equipment()
  for _, eq in ipairs(PROBE_EQUIPMENT) do
    local name = eq.name
    if name == "fusion-reactor-equipment" then name = power end
    if prototypes.item[name] then
      for _ = 1, (eq.count or 1) do
        grid.put({ name = name, count = 1 })
      end
    end
  end
end

local function set_land_permission(player, allowed)
  local group_name = "player_" .. player.index
  local group = game.permissions.get_group(group_name)
  if group then
    group.set_allows_action(defines.input_action.land_at_planet, allowed)
  end
end

local function find_probe_entity(planet_name, unit_num)
  local planet = game.planets[planet_name]
  if not planet or not planet.surface then return nil end
  for _, entity in pairs(planet.surface.find_entities_filtered({ name = PROBE_NAME })) do
    if entity.unit_number == unit_num and entity.valid then
      return entity
    end
  end
  return nil
end

local function find_probe_owner(unit_number)
  for _, player in pairs(game.players) do
    if player.valid then
      ensure_player_storage(player.index)
      for _, unit_num in pairs(storage.players[player.index].probes) do
        if unit_num == unit_number then
          return player
        end
      end
    end
  end
  return nil
end

-- Enter probe remotely: camera moves to probe's surface, character stays on mainframe
local function enter_probe_remote(player, probe)
  if not player.valid or not probe or not probe.valid then return end
  -- Store character reference before switching controllers
  if player.character and player.character.valid then
    ensure_player_storage(player.index)
    storage.players[player.index].mainframe_character = player.character
  end
  player.set_controller({
    type = defines.controllers.remote,
    surface = probe.surface,
    position = probe.position
  })
  probe.set_driver(player)
end

-- Exit probe and return to mainframe character
local function return_to_mainframe(player)
  if not player.valid then return end
  local vehicle = player.vehicle
  if vehicle and vehicle.valid then
    vehicle.set_driver(nil)
  end
  ensure_player_storage(player.index)
  local char = storage.players[player.index].mainframe_character
  if char and char.valid then
    player.set_controller({
      type = defines.controllers.remote,
      surface = char.surface,
      position = char.position
    })
    player.set_controller({
      type = defines.controllers.character,
      character = char
    })
    storage.players[player.index].mainframe_character = nil
  else
    if player.character and player.character.valid then
      local char = player.character
      player.set_controller({
        type = defines.controllers.remote,
        surface = char.surface,
        position = char.position
      })
      player.set_controller({
        type = defines.controllers.character,
        character = char
      })
    else
      player.set_controller({
        type = defines.controllers.remote,
        surface = storage.platform.surface,
        position = { x = 0, y = 0 }
      })
      player.create_character()
    end
    storage.players[player.index].mainframe_character = nil
  end
  gameplay.goto_platform(player)
end

-- Schedule remote probe entry for next tick (lets teleport complete first)
local function schedule_remote_entry(player_index, planet_name)
  if not storage.pending_remote_entries then
    storage.pending_remote_entries = {}
  end
  storage.pending_remote_entries[player_index] = planet_name
end

-- Process pending remote entries on next tick
script.on_event(defines.events.on_tick, function()
  if not storage.pending_remote_entries then return end
  local entries = storage.pending_remote_entries
  storage.pending_remote_entries = nil
  for player_index, planet_name in pairs(entries) do
    local player = game.players[player_index]
    if player and player.valid then
      ensure_player_storage(player_index)
      local unit_num = storage.players[player_index].probes[planet_name]
      if unit_num then
        local probe = find_probe_entity(planet_name, unit_num)
        if probe then
          enter_probe_remote(player, probe)
        end
      end
    end
  end
end)

-- Cargo pod landed: spawn probe, send player back to mainframe, schedule remote entry
script.on_event(defines.events.on_cargo_pod_finished_descending, function(event)
  if not event.player_index or event.launched_by_rocket then return end
  local player = game.players[event.player_index]
  if not player or not player.valid then return end
  local cargo_pod = event.cargo_pod
  if not cargo_pod or not cargo_pod.valid then return end

  local surface = cargo_pod.surface
  local planet = surface and surface.planet
  if not planet then return end
  local planet_name = planet.name

  ensure_player_storage(player.index)
  local probes = storage.players[player.index].probes

  -- If probe already exists on this planet, reuse it
  local existing_unit = probes[planet_name]
  if existing_unit then
    local existing_probe = find_probe_entity(planet_name, existing_unit)
    if existing_probe then
      if cargo_pod.valid then cargo_pod.destroy() end
      set_land_permission(player, false)
      gameplay.goto_platform(player)
      schedule_remote_entry(player.index, planet_name)
      return
    end
    probes[planet_name] = nil
  end

  local pos = cargo_pod.position
  if cargo_pod.valid then cargo_pod.destroy() end

  local probe = surface.create_entity({
    name = PROBE_NAME,
    position = pos,
    force = player.force
  })
  if not probe or not probe.valid then return end

  equip_probe(probe)
  local main_inv = player.get_main_inventory()
  if main_inv and prototypes.item["construction-robot"] then
    main_inv.insert({ name = "construction-robot", count = 25 })
  end
  probes[planet_name] = probe.unit_number
  set_land_permission(player, false)

  gameplay.goto_platform(player)
  schedule_remote_entry(player.index, planet_name)
end)

-- Surface swap shortcut: show selection GUI with all available probes + mainframe
script.on_event(defines.events.on_lua_shortcut, function(event)
  if event.prototype_name ~= SURFACE_SWAP_SHORTCUT then return end
  local player = game.players[event.player_index]
  if not player or not player.valid or not storage.platform or not storage.platform.valid then return end

  ensure_player_storage(player.index)
  local probes = storage.players[player.index].probes

  local choices = {}
  for planet_name, unit_num in pairs(probes) do
    local probe = find_probe_entity(planet_name, unit_num)
    if probe then
      table.insert(choices, { value = planet_name, label = planet_name })
    else
      probes[planet_name] = nil
    end
  end

  if #choices == 0 then return end

  table.insert(choices, 1, { value = "mainframe", label = "Mainframe" })

  local gui = player.gui.screen
  if gui.paratoxic_swap_frame then gui.paratoxic_swap_frame.destroy() end
  local frame = gui.add({
    type = "frame",
    name = "paratoxic_swap_frame",
    caption = { "shortcut-name.paratoxic-surface-swap" },
    direction = "vertical"
  })
  for _, choice in ipairs(choices) do
    local btn = frame.add({
      type = "button",
      name = "paratoxic_swap_" .. choice.value,
      caption = choice.label
    })
    btn.style.minimal_width = 150
  end
  frame.add({ type = "button", name = "paratoxic_swap_close", caption = "Close" })
  frame.force_auto_center()
end)

-- Handle surface swap GUI clicks
script.on_event(defines.events.on_gui_click, function(event)
  local elem = event.element
  if not elem or not elem.valid or not elem.name then return end
  if not elem.name:find("^paratoxic_swap_") then return end

  local player = game.players[event.player_index]
  if not player or not player.valid then return end

  local btn_name = elem.name
  local frame = player.gui.screen.paratoxic_swap_frame
  if frame then frame.destroy() end

  if btn_name == "paratoxic_swap_close" then return end

  if btn_name == "paratoxic_swap_mainframe" then
    return_to_mainframe(player)
    return
  end

  local planet_name = btn_name:sub(#"paratoxic_swap_" + 1)
  ensure_player_storage(player.index)
  local probes = storage.players[player.index].probes
  local unit_num = probes[planet_name]
  if not unit_num then return end

  local probe = find_probe_entity(planet_name, unit_num)
  if not probe then
    probes[planet_name] = nil
    return
  end

  -- Exit current probe if driving one
  local vehicle = player.vehicle
  if vehicle and vehicle.valid then
    vehicle.set_driver(nil)
  end

  enter_probe_remote(player, probe)
end)

-- Probe death: clean up storage, return owner to mainframe
script.on_event(defines.events.on_entity_died, function(event)
  local entity = event.entity
  if not entity or entity.name ~= PROBE_NAME then return end

  local owner = find_probe_owner(entity.unit_number)
  if owner then
    ensure_player_storage(owner.index)
    for planet_name, unit_num in pairs(storage.players[owner.index].probes) do
      if unit_num == entity.unit_number then
        storage.players[owner.index].probes[planet_name] = nil
        break
      end
    end
    set_land_permission(owner, true)
    return_to_mainframe(owner)
  end
end)

script.on_event(defines.events.on_segmented_unit_died, function(event)
  local entity = event.segmented_unit
  if not entity or not entity.valid or entity.prototype.name ~= PROBE_NAME then return end

  local owner = find_probe_owner(entity.unit_number)
  if owner then
    ensure_player_storage(owner.index)
    for planet_name, unit_num in pairs(storage.players[owner.index].probes) do
      if unit_num == entity.unit_number then
        storage.players[owner.index].probes[planet_name] = nil
        break
      end
    end
    set_land_permission(owner, true)
    return_to_mainframe(owner)
  end
end)

-- Ownership protection: eject non-owners from probes
script.on_event(defines.events.on_player_driving_changed_state, function(event)
  local player = game.players[event.player_index]
  if not player or not player.valid then return end
  local vehicle = player.vehicle
  if not vehicle or not vehicle.valid or vehicle.name ~= PROBE_NAME then return end

  local owner = find_probe_owner(vehicle.unit_number)
  if not owner or owner.index ~= player.index then
    vehicle.set_driver(nil)
  end
end)

-- Disable land_at_planet when player already has a probe on the orbiting planet
script.on_nth_tick(60, function()
  if not storage.platform or not storage.platform.valid then return end
  local platform = storage.platform
  if not platform.surface then return end
  local space_loc = platform.space_location
  if not space_loc then return end
  local planet_name = space_loc.name
  local platform_surface_index = platform.surface.index

  for _, player in pairs(game.players) do
    if not player.valid or not player.connected then goto next_player end
    if player.surface_index ~= platform_surface_index then goto next_player end

    ensure_player_storage(player.index)
    local probes = storage.players[player.index].probes
    local unit_num = probes[planet_name]
    local has_probe = false
    if unit_num then
      local probe = find_probe_entity(planet_name, unit_num)
      if probe then
        has_probe = true
      else
        probes[planet_name] = nil
      end
    end

    local group_name = "player_" .. player.index
    local group = game.permissions.get_group(group_name)
    if not group then
      group = game.permissions.create_group(group_name)
      group.add_player(player)
      group.set_allows_action(defines.input_action.add_permission_group, false)
      group.set_allows_action(defines.input_action.edit_permission_group, false)
      group.set_allows_action(defines.input_action.delete_permission_group, false)
    end
    if group then
      group.set_allows_action(defines.input_action.land_at_planet, not has_probe)
    end
    ::next_player::
  end
end)
