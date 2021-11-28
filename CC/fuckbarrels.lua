-- Create Above and Beyond Test of Patience automation
-- Seriously fuck barrels

while true do
  turtle.dig()
  for i=1,8 do
    turtle.select(i)
    local d = turtle.getItemDetail(i,true)
    if d then
      if d.lore and d.lore[1] == "The fabled prize awaits at the bottom..." then
        turtle.place()
      else
        turtle.dropUp()
      end
    end
  end
  turtle.select(1)
end