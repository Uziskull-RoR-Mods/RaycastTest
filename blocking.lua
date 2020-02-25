registercallback("preStep", function()
    misc.director:set("points", 0)
    for _, p in ipairs(misc.players) do
        p:set("pHmax", 0):set("pVmax", 0)
         :set("pGravity1", 0):set("pGravity2", 0)
         :set("activity", 69)
    end
end)