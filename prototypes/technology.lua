data:extend(
{
  {
    type = "technology",
    name = "pallets",
    icon = "__pallets__/graphics/technology/pallets.png",
    icon_size = 128,
    effects =
    {
      {
        type = "unlock-recipe",
        recipe = "empty-pallet"
      }
    },
    prerequisites = {"logistics-2"},
    unit =
    {
      count = 150,
      ingredients =
      {
        {"science-pack-1", 1},
        {"science-pack-2", 1}
      },
      time = 30
    },
    order = "c-o-a",
  }
})
