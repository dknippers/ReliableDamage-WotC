# Reliable Damage
Reliable Damage is an XCOM 2 Mod which attempts to reduce the amount of RNG present in the game, mainly by changing the way damage is applied in the game.
Every shot taken by the player or an Alien in XCOM 2 has an associated hit chance (= probability the shot will hit) and a damage value.
By default, the shot will either hit or miss, dealing full damage or no damage at all, respectively.

With this mod, we calculate the shot's expected value (= hit chance * damage) and apply that to the target instead. This greatly reduces the variance in applied damage, and lowers the amount of surprises (both pleasant and unpleasant). Because the core game works with integer damage values throughout, it is virtually impossible to apply floating point damage values. Therefore, this mod uses one more roll to determine the final damage value. For example, when a player takes a 60% shot for 4 damage the expected value is 2.4, which we then interpret as 60% change to deal 2 damage and 40% change to deal 3 damage, and roll for the final value.

## Steam Workshop
The mod is available in the [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=688497616)