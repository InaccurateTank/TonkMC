-- Create Above and Beyond Test of Patience automation
-- Seriously fuck barrels

while true do
  turtle.dig()
  for i=1,16 do
    turtle.select(i)
    local detail = turtle.getItemDetail(i)
    if detail and detail.name == "minecraft:barrel" then
      detail = turtle.getItemDetail(i, true)
      if detail.lore and detail.lore[1] == "The fabled prize awaits at the bottom..." then
        turtle.place()
        break
      end
    end
  end
  for i=1,16 do
    turtle.select(i)
    local detail = turtle.getItemDetail(i)
    if detail then
      turtle.dropUp()
    end
  end
  turtle.select(1)
end