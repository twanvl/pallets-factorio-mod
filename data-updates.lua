-- This auto-generates pallet items and fill/empty recipes for every item
-- Based on auto barreling from __base__/data-updates.lua


-- Item icon masks
local pallet_base_mask = "__pallets__/graphics/icons/pallet-base.png"
-- Recipe icon masks
local pallet_load_base_mask = "__pallets__/graphics/icons/pallet-load-base.png"
local pallet_unload_base_mask = "__pallets__/graphics/icons/pallet-unload-base.png"
local empty_pallet_item

-- Number of items that fit on a pallet
local items_per_pallet = settings.startup["pallet-stack-size"].value
local limit_items_per_pallet_to_stack_size = false
-- Allow barrels on pallets?
local allow_barrels_on_pallets = false
-- Allow empty/loaded pallets onto pallets?
local allow_empty_pallets_on_pallets = true
local allow_pallets_on_pallets = false
-- Should the stack size of pallets be >1?
local allow_pallet_stacks = false

-- Crafting energy per pallet load recipe
local energy_per_load = 0.2
-- Crafting energy per pallet unload recipe
local energy_per_unload = 0.2
-- If the load/unload recipes effect production statistics
local hide_palleting_from_production_stats = true
-- If the load/unloaf recipes should be included in the list of valid recipes things can use when calculating raw materials
local allow_palleting_decomposition = false

local function get_item(name)
  local items = data.raw["item"]
  if items then
    return items[name]
  end
  return nil
end

local function get_technology(name)
  local technologies = data.raw["technology"]
  if technologies then
    return technologies[name]
  end
  return nil
end

local function contains(table,element)
  if table then
    for _, value in pairs(table) do
      if value == element then
        return true
      end
    end
  end
  return false
end

-- Generates the icons definition for a loaded pallet item
local function generate_pallet_item_icons(item)
  -- TODO: shifts are broken: they don't scale with the icon
  return
  {
    {
      icon = pallet_base_mask
    },
    {
      icon = item.icon,
      scale = 0.75,
      shift = {0, -1}
    }
  }
end

local function generate_load_pallet_icons(item)
  return
  {
    {
      icon = pallet_load_base_mask
    },
    {
      icon = item.icon,
      scale = 0.5,
      shift = {-8, -8}
    }
  }
end

local function generate_unload_pallet_icons(item)
  return
  {
    {
      icon = pallet_unload_base_mask
    },
    {
      icon = item.icon,
      scale = 0.5,
      shift = {8, 8}
    }
  }
end


local function get_localised_item_name(item)
  -- For items, we should look in item-name.x
  -- For entities, look at entity-name.x
  -- This is a bit hacky, but I don't know where factorio gets the name of items that are also entities and equipment, but which don't have an item-name entry in the local
  if item.localised_name then
    return item.localised_name
  elseif item.place_result then
    return {"entity-name." .. item.name}
  elseif item.placed_as_equipment_result then
    return {"equipment-name." .. item.name}
  else
    return {"item-name." .. item.name}
  end
end

-- Generates a pallet item for stacks of the 
local function create_pallet_item(item)
  local result =
  {
    type = "item",
    name = item.name .. "-pallet",
    localised_name = {"item-name.loaded-pallet", get_localised_item_name(item)},
    icons = generate_pallet_item_icons(item),
    icon_size = 32,
    flags = {"goes-to-main-inventory"},
    subgroup = "load-pallet",
    order = "b[" .. item.name .. "-pallet]",
    stack_size = (allow_pallet_stacks and empty_pallet_item.stack_size or 1)
  }

  if contains(item.flags,"hidden") then
    table.insert(result.flags, "hidden")
  end

  data:extend({result})
  return result
end

local function get_or_create_pallet_item(item)
  local existing_item = get_item(item.name .. "-pallet")
  if existing_item then
    return existing_item
  end
  return create_pallet_item(item)
end


local function get_items_per_pallet(item)
  local n = items_per_pallet
  if limit_items_per_pallet_to_stack_size and n > item.stack_size then
    n = item.stack_size
  end
  return n
end

local function create_load_pallet_recipe(item)
  local recipe =
  {
    type = "recipe",
    name = "load-" .. item.name .. "-pallet",
    localised_name = {"recipe-name.load-pallet", get_localised_item_name(item)},
    category = "advanced-crafting",
    energy_required = energy_per_load,
    subgroup = "load-pallet",
    order = "b[load-" .. item.name .. "-pallet]",
    enabled = false,
    icons = generate_load_pallet_icons(item),
    icon_size = 32,
    ingredients =
    {
      {type = "item", name = item.name, amount = get_items_per_pallet(item)},
      {type = "item", name = empty_pallet_item.name, amount = 1},
    },
    results=
    {
      {type = "item", name = item.name .. "-pallet", amount = 1}
    },
    hide_from_stats = hide_palleting_from_production_stats,
    allow_decomposition = allow_palleting_decomposition
  }

  data:extend({recipe})
  return recipe
end

local function create_unload_pallet_recipe(item)
  local recipe =
  {
    type = "recipe",
    name = "unload-" .. item.name .. "-pallet",
    localised_name = {"recipe-name.unload-pallet", get_localised_item_name(item)},
    category = "advanced-crafting",
    energy_required = energy_per_unload,
    subgroup = "unload-pallet",
    order = "c[unload-" .. item.name .. "-pallet]",
    enabled = false,
    icons = generate_unload_pallet_icons(item),
    icon_size = 32,
    ingredients =
    {
      {type = "item", name = item.name .. "-pallet", amount = 1}
    },
    results=
    {
      {type = "item", name = item.name, amount = get_items_per_pallet(item)},
      {type = "item", name = empty_pallet_item.name, amount = 1}
    },
    hide_from_stats = hide_palleting_from_production_stats,
    allow_decomposition = allow_palleting_decomposition
  }

  data:extend({recipe})
  return recipe
end

local function get_recipes_for_pallet(item)
  local recipes = data.raw["recipe"]
  if recipes then
    return recipes["load-" .. item.name .. "-pallet"], recipes["unload-" .. item.name .. "-pallet"]
  end
  return nil
end

local function get_or_create_pallet_recipes(item)
  local load_recipe, unload_recipe = get_recipes_for_pallet(item)

  if not load_recipe then
    load_recipe = create_load_pallet_recipe(item)
  end
  if not unload_recipe then
    unload_recipe = create_unload_pallet_recipe(item)
  end

  return load_recipe, unload_recipe
end


-- Adds the provided pallet recipe and load/empty recipes to the technology as recipe unlocks if they don't already exist
local function add_pallet_to_technology(load_recipe, unload_recipe, technology)
  local unlock_key = "unlock-recipe"
  local effects = technology.effects

  if not effects then
    technology.effects = {}
    effects = technology.effects
  end

  local add_load_recipe = true
  local add_unload_recipe = true

  for k,v in pairs(effects) do
    if k == unlock_key then
      local recipe = v.recipe
      if recipe == load_recipe.name then
        add_load_recipe = false
      elseif recipe == unload_recipe.name then
        add_unload_recipe = false
      end
    end
  end

  if add_load_recipe then
    table.insert(effects, {type = unlock_key, recipe = load_recipe.name})
  end
  if add_unload_recipe then
    table.insert(effects, {type = unlock_key, recipe = unload_recipe.name})
  end
end

local function allow_on_pallet(item)
  if contains(item.flags,"hidden") then
    return false
  elseif (item.auto_pallet == nil or item.auto_pallet) and item.icon then
    if item.subgroup == "fill-barrel" or item.name == "empty-barrel" then
      return allow_barrels_on_pallets
    elseif item.name == "empty-pallet" then
      return allow_empty_pallets_on_pallets
    elseif item.subgroup == "load-pallet" then
      return allow_pallets_on_pallets
    else
      return true
    end
  end
  return false
end

local function process_items(items, technology)
  if not items then
    log("Auto pallet generation is disabled.")
  end

  for name,item in pairs(items) do
    if allow_on_pallet(item) then
      -- check if a pallet item already exists for this item if not - create one
      local pallet_item = get_or_create_pallet_item(item)

      -- check if the item has a palleting recipe if not - create one
      local load_recipe, unload_recipe = get_or_create_pallet_recipes(item)

      -- check if the loading/unloading recipe exists in the unlock list of the technology if not - add it
      add_pallet_to_technology(load_recipe, unload_recipe, technology)
    end
  end
end

empty_pallet_item = get_item("empty-pallet")
process_items(data.raw["item"], get_technology("pallets"))

