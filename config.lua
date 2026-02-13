Config = {}

Config.MarketLocation = vector3(-52.0, -1096.0, 26.0)
Config.MarketHeading = 160.0

Config.NPC = {
    model = "a_m_m_prolhost_01",
    coords = vector4(-51.48, -1094.59, 25.42, 160.0)
}

Config.Blip = {
    sprite = 225,
    color = 2,
    scale = 0.8,
    label = "automobiliu turgus"
}

Config.Slots = {
    {coords = vector3(-44.1, -1094.1, 25.4), heading = 160.0},
    {coords = vector3(-46.5, -1095.4, 25.4), heading = 160.0},
    {coords = vector3(-49.2, -1096.3, 25.4), heading = 160.0},
    {coords = vector3(-52.0, -1097.5, 25.4), heading = 160.0},
    {coords = vector3(-54.8, -1098.5, 25.4), heading = 160.0},
}

Config.Commission = 0.05

-- Tekstai (Lietuviškai)
Config.Locales = {
    ["sell_car"] = "Paspauskite ~INPUT_CONTEXT~, kad parduotumėte savo automobilį",
    ["inspect_car"] = "~g~[E]~w~ Apžiūrėti automobilį",
    ["no_vehicle"] = "Turite būti automobilyje, kad jį parduotumėte!",
    ["not_owner"] = "Šis automobilis nepriklauso jums!",
    ["lot_full"] = "Aikštelė pilna! Nėra laisvų vietų.",
    ["listed_for"] = "Automobilis įkeltas į turgų už $",
    ["bought_veh"] = "Nusipirkote automobilį! Jis dabar jūsų garaže.",
    ["not_enough_money"] = "Jums nepakanka pinigų!",
    ["sold_notify"] = "Jūsų automobilis (Numeriai: %s) buvo parduotas už $%s"
}