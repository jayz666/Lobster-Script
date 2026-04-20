Config = {}

-- Main Configuration
Config.Debug = false
Config.Locale = 'en'

-- Fishing Areas (vector3 coordinates)
Config.FishingAreas = {
    {
        name = 'Vespucci Beach',
        coords = vector3(-1195.0, -1510.0, 4.3),
        radius = 100.0,
        maxTraps = 3
    },
    {
        name = 'Del Perro Beach',
        coords = vector3(-1650.0, -950.0, 13.0),
        radius = 80.0,
        maxTraps = 2
    },
    {
        name = 'Paleto Cove',
        coords = vector3(-440.0, 6350.0, 30.0),
        radius = 120.0,
        maxTraps = 4
    }
}

-- Shop Locations for buying traps and bait
Config.Shops = {
    {
        name = 'Bait Shop - Vespucci',
        coords = vector4(-1150.0, -1525.0, 4.3, 25.0),
        blip = {
            sprite = 68,
            color = 3,
            scale = 0.7
        }
    },
    {
        name = 'Marine Supply - Paleto',
        coords = vector4(-275.0, 6350.0, 31.5, 45.0),
        blip = {
            sprite = 68,
            color = 3,
            scale = 0.7
        }
    }
}

-- Market Locations for selling lobsters
Config.Markets = {
    {
        name = 'Seafood Market - Vespucci',
        coords = vector4(-1150.0, -1420.0, 4.3, 180.0),
        blip = {
            sprite = 476,
            color = 2,
            scale = 0.7
        }
    },
    {
        name = 'Fish Market - Humane Labs',
        coords = vector4(3300.0, 5150.0, 18.0, 90.0),
        blip = {
            sprite = 476,
            color = 2,
            scale = 0.7
        }
    }
}

-- Items and Prices
Config.Items = {
    lobster_trap = {
        name = 'Lobster Trap',
        price = 500,
        max = 5
    },
    bait = {
        name = 'Fish Bait',
        price = 10,
        max = 50
    },
    lobster = {
        name = 'Lobster',
        price = 150,
        minSize = 1,
        maxSize = 5
    },
    rare_lobster = {
        name = 'Rare Lobster',
        price = 500,
        chance = 10 -- 10% chance
    }
}

-- Fishing Mechanics
Config.Fishing = {
    trapWaitTime = 300000, -- 5 minutes in milliseconds
    baitBonus = 0.3, -- 30% increase in catch rate with bait
    baseCatchChance = 0.6, -- 60% base chance to catch something
    maxLobstersPerTrap = 3,
    skillMultiplier = 0.1 -- 10% bonus per skill level
}

-- Skills System
Config.Skills = {
    enabled = true,
    xpPerCatch = 10,
    xpPerRareCatch = 25,
    maxLevel = 10,
    bonuses = {
        [1] = { catchBonus = 0.05, rareBonus = 0.02 },
        [3] = { catchBonus = 0.10, rareBonus = 0.05 },
        [5] = { catchBonus = 0.15, rareBonus = 0.08 },
        [7] = { catchBonus = 0.20, rareBonus = 0.12 },
        [10] = { catchBonus = 0.30, rareBonus = 0.20 }
    }
}

-- Animations and Props
Config.Animations = {
    placingTrap = {
        anim = 'world_human_gardener_plant',
        dict = 'amb@world_human_gardener_plant@male@base',
        time = 3000
    },
    harvestingTrap = {
        anim = 'world_human_gardener_plant',
        dict = 'amb@world_human_gardener_plant@male@base',
        time = 4000
    },
    trapProp = 'prop_beach_fire'
}

-- Target System (ox_target or qb-target)
Config.Target = 'ox_target' -- Change to 'qb_target' if using qb-target

-- Notifications
Config.Notify = {
    type = 'ox_lib', -- 'ox_lib', 'qb-ui', or 'chat'
    position = 'top-right'
}
