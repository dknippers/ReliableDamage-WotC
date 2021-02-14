[h1]Description[/h1]
This mod attempts to remove the various RNG elements present in the game when you take a shot. Mainly, all shots will now hit but deal the expected value of the shot (= hit chance * damage) as damage. That value is much lower than the full damage, obviously. This averages out to the exact same amount of total damage that is delivered, just without the RNG of critting / hitting / grazing / missing.

[h1]XCOM 2: War of the Chosen[/h1]
This mod has NOT been updated for War of the Chosen. I do not own the game, and do not know if I will purchase it any time soon and have time to then update this mod. I actually do not know if it works with WotC or not, but presumably it does not.

Therefore, if you want this mod to be updated and have some programming skills yourself, by all means take my source code (should be in this mod's workshop folder on disk) and update it for War of the Chosen. Then you can just upload it as a mod of your own. I'd appreciate it if you mention this mod as inspiration in that case :) Let me know, and I'll link it from here as well so more people can find it.

[h1]Features[/h1]
[list]
[*] Every shot has a 100% hit chance, but lowered damage so the expected value of the shot is unchanged.
[*] Weapon spread is removed (can be reverted in Config\XComGameData_WeaponData.ini)
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
[*] [b]RoundingEnabled[/b] - Rounds all damage values to whole numbers. 0 to disable (default), 1 to enable.
[*] [b]OverwatchRemovalMinimumDamage[/b] - Minimum damage required to cancel Overwatch. Default = 0 (all shots that hit will cancel Overwatch).
[*] [b]OverwatchRemovalMinimumHitChance[/b] - Minimum hit chance required to cancel Overwatch. Default = 60 (only shots of 60% or higher will cancel Overwatch).
[*] [b]KeepCrit[/b] - Keep Critical Shots like in regular XCOM. 0 to disable (default), 1 to enable.
[*] [b]KeepGraze[/b] - Keep Graze Shots (Dodge) like in regular XCOM. 0 to disable (default), 1 to enable
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

[h1]Long War 2 Compatibility[/h1]
[b]TL;DR[/b]: Should mostly work but due to changed mechanics the damage values might be a bit off.

When playing LW2 with this mod for a little bit I did not notice anything to be particularly broken. That is, the damage values of shots seemed to be adjusted properly and applied correctly. This was also true for many custom LW2 damage effects that I came across (e.g. Light Em Up).

However, after studying the mechanics of LW2 in a bit more depth, I think there may be a couple of issues when using this mod together with LW2. For example, they changed the way Crits / Grazes work. Crits promote a graze to a hit, or a hit to a crit whereas Grazes demote crits to hits and hits to grazes, and possibly grazes to misses as well. Therefore, the damage numbers generated by my mod might not be exactly the expected value for LW2 as I calculate them based on Vanilla's mechanics (simple: Crit adds damage, Graze removes damage). While I believe LW2's complex system does not change the overall expected value of a shot much (which is what I calculate), it likely changes it in some ways.

In addition, LW2 adds many new weapon effects which may or may not work automatically. Most should work fine, but there was for example an issue with Ranger's Double Barrel ability that had to be fixed. 

Lastly, LW2 overrides the base game classes that are responsible for calculating damage values and I do not know if they play nicely together in all cases. I've not noticed any glaring issues in the first couple of hours of gameplay but I cannot be sure.

If you find any issues, please let me know in the comments.