# QBX Lobster Fishing Script

A comprehensive lobster fishing script for QBX (QBCore) FiveM servers with realistic mechanics, skill progression, and economy integration.

## Features

- **Realistic Fishing Mechanics**: Place traps in designated areas, wait for catch, harvest rewards
- **Skill Progression System**: Level up your fishing skills for better catch rates
- **Economy Integration**: Buy traps/bait, sell lobsters at markets
- **Multiple Fishing Areas**: Vespucci Beach, Del Perro Beach, Paleto Cove
- **Rare Lobsters**: Chance to catch valuable rare lobsters
- **Target System Integration**: Full ox_target support for all interactions
- **Modern UI**: Progress bars, context menus, notifications
- **Database Integration**: Persistent skill levels and XP

## Requirements

- **QBX Core**: Latest version
- **ox_lib**: For UI functions and utilities
- **ox_target**: For interaction system (required)
- **MySQL**: For database storage

## Installation

**Self-Installing Setup:**

1. Download the script and place it in your `resources` folder
2. Rename the folder to `qbx_lobsterfishing`
3. Add `ensure qbx_lobsterfishing` to your `server.cfg`
4. Restart the server or start the resource

**The script automatically:**
- Creates all necessary database tables
- Registers the "Lobster Fisher" job with 3 grades
- Adds all required items to the inventory system
- Sets up placeholder item images
- Configures all target zones and interactions

**No manual database setup required!**

## Configuration

Edit `shared/config.lua` to customize:

- Fishing areas and trap limits
- Shop and market locations
- Item prices and rewards
- Skill system settings
- Animation and prop settings
- Target system choice

## Usage

### For Players

1. **Buy Equipment**: Visit bait shops to purchase lobster traps and bait
2. **Find Fishing Areas**: Go to designated beaches (marked on map with green circles)
3. **Place Traps**: Use target interaction in fishing areas (look for anchor icon)
4. **Wait**: Wait 5 minutes for traps to catch lobsters
5. **Harvest**: Return to traps and use target interaction (look for fish icon)
6. **Sell**: Visit seafood markets to sell your lobsters

### Target Interactions

- **Bait Shop**: Target the shop counter to open the menu
- **Seafood Market**: Target the market counter to sell lobsters
- **Fishing Areas**: Target within fishing areas to place traps
- **Placed Traps**: Target your placed traps to harvest them

### Commands

- `/lobsterstats` - Check your fishing skill level

### Admin Commands

- `/lobsterskill [playerId] [level]` - Set player's fishing skill level

## Job System

The script automatically creates the "Lobster Fisher" job with the following grades:

| Grade | Name | Payment | Boss |
|-------|------|---------|------|
| 0 | Novice | $150/hr | No |
| 1 | Expert | $300/hr | No |
| 2 | Master | $450/hr | Yes |

Players can join this job at any time (no whitelist required) and earn hourly payments while fishing.

## Items

| Item | Description | Price |
|------|-------------|-------|
| Lobster Trap | Used to catch lobsters | $500 |
| Fish Bait | Increases catch rate | $10 |
| Lobster | Regular lobster | $150 |
| Rare Lobster | Valuable specimen | $500 |

## Skill System

Players gain XP for catching lobsters:
- **Regular Lobster**: 10 XP
- **Rare Lobster**: 25 XP

Skill bonuses include:
- **Level 1**: +5% catch rate, +2% rare chance
- **Level 3**: +10% catch rate, +5% rare chance
- **Level 5**: +15% catch rate, +8% rare chance
- **Level 7**: +20% catch rate, +12% rare chance
- **Level 10**: +30% catch rate, +20% rare chance

## Locations

### Bait Shops
- **Vespucci Beach**: Near fishing area
- **Paleto Cove**: Marine supply store

### Seafood Markets
- **Vespucci Market**: Central Los Santos
- **Humane Labs Market**: Rural area

### Fishing Areas
- **Vespucci Beach**: Max 3 traps
- **Del Perro Beach**: Max 2 traps  
- **Paleto Cove**: Max 4 traps

## Automatic Setup

The script handles all setup automatically on first start:

### Database Tables Created:
- `player_lobster_skills` - Stores player fishing skill levels and XP
- `jobs` - Job system table (if not exists)

### Job Created:
- **Lobster Fisher** - Non-whitelisted job with 3 grades

### Items Registered:
- `lobster` - Regular lobster (1kg)
- `rare_lobster` - Rare lobster (1.5kg) 
- `lobster_trap` - Fishing trap (5kg)
- `bait` - Fish bait (0.1kg)

### Images Setup:
- Creates `/images` folder structure
- Generates placeholder entries for all item images

### Console Output:
```
[QBX Lobster Fishing] Database tables created successfully
[QBX Lobster Fishing] Job "Lobster Fisher" created successfully  
[QBX Lobster Fishing] Items registered successfully
[QBX Lobster Fishing] Item images setup completed
```

## Customization

### Adding New Fishing Areas

```lua
{
    name = 'New Beach',
    coords = vector3(x, y, z),
    radius = 100.0,
    maxTraps = 3
}
```

### Changing Prices

Edit the `Config.Items` table in `shared/config.lua`:

```lua
Config.Items.lobster.price = 200  -- Change lobster price
Config.Items.lobster_trap.price = 750  -- Change trap price
```

### Adjusting Mechanics

```lua
Config.Fishing.trapWaitTime = 300000  -- 5 minutes in milliseconds
Config.Fishing.baseCatchChance = 0.6  -- 60% base catch chance
Config.Fishing.maxLobstersPerTrap = 3  -- Max lobsters per trap
```

## Troubleshooting

### Common Issues

1. **Traps not placing**: Ensure you're in a designated fishing area
2. **Can't harvest**: Wait the full 5 minutes after placing traps
3. **No market blips**: Check blip settings in config
4. **Target not working**: Ensure correct target system is configured

### Debug Mode

Enable debug mode in config to see additional information:

```lua
Config.Debug = true
```

## Support

For issues and support:
1. Check the configuration files
2. Ensure all dependencies are installed
3. Verify database connection
4. Test with debug mode enabled

## Changelog

### Version 1.0.0
- Initial release
- Core fishing mechanics
- Skill progression system
- Economy integration
- Multi-location support
- Target system compatibility

## License

This script is released under the MIT License. Feel free to modify and distribute as needed.
