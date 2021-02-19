[h1]Description[/h1]
This mod attempts to remove the various RNG elements present in the game when you take a shot. Mainly, all shots will now hit but deal the expected value of the shot (= hit chance * damage) as damage. That value is much lower than the full damage, obviously. This averages out to the exact same amount of total damage that is delivered, just without the RNG of critting / hitting / grazing / missing.

[h1]Features[/h1]
[list]
[*] Every shot has a 100% hit chance, but lowered damage so the expected value of the shot is unchanged.
[*] Weapon spread is removed (can be reverted in Config\XComReliableDamage.ini)
[*] Critical damage / Graze shots are removed but their effects are incorporated in every shot instead (i.e., 25% chance to crit for an additional 4 damage would simply do +1 damage on each shot instead). This is configurable, both types of shots can be restored to normal if desired.
[*] Abilities like Viper's Bind can still miss (as for example the pull effect would be heavily OP with 100%)

[*] Each shot applies the expected value of the shot (hit chance * damage), and cannot miss as a result.
[*] Example; a 4 damage shot with a 50% chance to hit will now have a 100% chance to do 2 damage.

[*] When <hit_chance> * <weapon_damage> is a fractional number, we will roll for the final integer value to deal as damage, with appropriate probabilities.
[*] Example: a 4 damage shot with a 60% chance to hit means the expected value would be 4 * 0.6 = 2.4. We convert this to a 60% chance of 2 damage and a 40% chance of 3 and will roll for the resulting value.

[*] The shot HUD is adjusted to display the "expected value" of the shot, which can be a fractional number.
[*] Example; when the shot HUD display "3.25", it means there is a 75% chance to do 3 damage and a 25% chance to do 4 damage.

[*] For more information on implementation details look through the source, I commented as much as I could.
[*] Log entries for every shot are written to the Launch.log file, with information on how exactly the damage of a shot was calculated (can be found in <USER_FOLDER>\Documents\My Games\XCOM2\XComGame\Logs\, CTRL+F for "ReliableDamage").
[/list]

[h1]Updates[/h1]
Look in the [url=http://steamcommunity.com/sharedfiles/filedetails/changelog/688497616]Change Notes section[/url].

[h1]Installation directory[/h1]
This mod is installed to \SteamApps\workshop\content\268500\688497616

[h1]Configuration[/h1]
Configuration options can be set in Config\XComReliableDamage.ini.
That file also contains a full description of each option, so look there for more in depth information.
[list]
[*] [b]OverwatchRemovalMinimumDamage[/b] - Minimum damage required to cancel Overwatch. Default = 2.
[*] [b]OverwatchRemovalMinimumHitChance[/b] - Minimum hit chance required to cancel Overwatch. Default = 50.
[*] [b]KeepCrit[/b] - Keep Critical Shots like in regular XCOM. 0 to disable (default), 1 to enable.
[*] [b]KeepGraze[/b] - Keep Graze Shots (Dodge) like in regular XCOM. 0 to disable (default), 1 to enable
[*] [b]RemoveDamageSpread[/b] - Removes damage spread from weapons and abilities. 0 to retain all damage spread, 1 to remove.
[/list]

[h1]Compatibility[/h1]
I have played with my mod and many others simultaneously, without any compatibility issues.
These mods include:
[list]
[*] Numeric Health Display
[*] Free Camera Rotation
[*] Stop Wasting My Time
[*] Evac All
[*] Wound Recalibration
[*] Cost Based Ability Colors
[*] Gotcha (Flank Preview Evolved)
[*] Instant Avenger Menus
[/list]

[h1]Incompatibility[/h1]
Any mods that override UITacticalHUD_ShotHUD might cause issues.
I have heard from issues with these mods:
[list]
[*] Perfect Information (FPS drops)
[/list]

If you find any issues, please let me know in the comments.
