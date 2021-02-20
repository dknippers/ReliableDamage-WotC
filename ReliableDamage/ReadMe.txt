[h1]Description[/h1]
This mod attempts to remove various RNG elements present in the game when you take a shot. 
Mainly, all shots will now hit but deal the expected value of the shot (= <hit_chance> * <damage>) as damage. 
That value is much lower than the full damage, obviously. 
This averages out to the exact same amount of total damage that is delivered, just without the RNG of critting / hitting / grazing / missing.

[h1]Features[/h1]
[list]
[*] Each shot applies the expected value of the shot (<hit_chance> * <damage>) and always hits.
[list]
[*] Example; a 4 damage shot with a 50% chance to hit will now have a 100% chance to do 2 damage.
[/list]
[*] When <hit_chance> * <weapon_damage> is a fractional number, we will roll for the final integer value to deal as damage, with appropriate probabilities.
[list]
[*] Example: a 4 damage shot with a 60% chance to hit means the expected value would be 4 * 0.6 = 2.4. We convert this to a 60% chance of 2 damage and a 40% chance of 3 and will roll for the resulting value.
[/list]
[*] Weapon spread is removed (can be reverted in Config\XComReliableDamage.ini)
[*] Critical damage / Graze shots are removed but their effects are incorporated in every shot instead (i.e., 25% chance to crit for an additional 4 damage would simply do +1 damage on each shot instead). This is configurable, both types of shots can be restored to normal if desired.
[*] Abilities like Viper's Bind can still miss (as for example the pull effect would be heavily OP with 100%)
[/list]

[h1]Updates[/h1]
Look in the [url=http://steamcommunity.com/sharedfiles/filedetails/changelog/688497616]Change Notes section[/url].

[h1]Installation directory[/h1]
This mod is installed to \SteamApps\workshop\content\268500\688497616

[h1]Configuration[/h1]
Configuration options can be set in Config\XComReliableDamage.ini.
That file also contains a full description of each option, so look there for more in depth information.
[list]
[*] [b]RemoveDamageSpread[/b] - Removes damage spread from weapons and abilities. 0 to retain all damage spread, 1 to remove.
[/list]

[h1]Overrides[/h1]
This mod does not apply any hard overrides through XComGameEngine.ini. 
We do selectively replace instances of the following classes with customized versions through code:
[list]
[*] X2Effect_ApplyWeaponDamage
[*] X2AbilityToHitCalc_StandardAim
[/list]

[h1]Incompatible mods[/h1]
If you experience issues with other mods, please let me know and I will update the list below.
[list]
[*] ( none so far )
[/list]

If you find any issues, please let me know in the comments.
