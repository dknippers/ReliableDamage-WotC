[h1]Description[/h1]
This mod attempts to remove various RNG elements present in the game when you take a shot.
All shots will now hit but deal the expected value of the shot (<hit_chance> * <damage>) as damage rather than hit for 100% or miss for 0%.
This greatly reduces the variance in damage and makes damage output much more reliable.
Applying the expected value averages out to the exact same amount of total damage that is delivered, just without the RNG of critting / hitting / grazing / missing.

[h1]Features[/h1]
[list]
[*] Each shot always hits but applies the expected value of the shot (<hit_chance> * <damage>) rather than 100% or 0%.
[list]
[*] Example; a 6 damage shot with a 60% chance to hit has an expected value of 3.60.
[*] The game cannot handle float values for damage so we roll for the resulting damage which is either 3 (40%) or 4 (60%).
[*] In this example, your shot will thus always do between 3 and 4 damage. Way more reliable than the default 0 (miss) or 6 (hit).
[/list]
[*] Critical damage / Graze shots are removed but their effects are incorporated in every shot instead (i.e., 25% chance to crit for an additional 4 damage would simply do +1 damage on each shot instead). This is configurable, both types of shots can be restored to normal if desired.
[*] Abilities like Viper's Bind and Skirimisher's Justice are not influenced and can still miss of course.
[*] All Weapon spread is removed
[list]
[*] By default a bunch of weapons have weapon spread. This simply means a weapon will not do exactly X damage but can do anywhere from X-S to X+S damage where S is the spread.
[*] Spread only increases variance and does not impact the expected value of a shot so can be safely removed for more reliable damage.
[/list]
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
[*] [b]AdjustCriticalHits[/b] - Critical hits can no longer occur but their bonus damage is incorporated into every shot instead.
[list]
[*] Set to 0 to revert to default XCOM behavior
[/list]
[*] [b]AdjustGrazeHits[/b] - Graze hits can no longer occur but their damage reduction is incorporated into every shot instead.
[list]
[*] Set to 0 to revert to default XCOM behavior
[/list]
[*] [b]AdjustPlusOne[/b] - Incorporate the "PlusOne" damage of certain weapons into every shot instead.
[list]
[*] For example, a Pistol has a PlusOne stat of 50. This means 50% of the time it will deal +1 damage. This mod will simply add 0.5 to the expected value of every shot instead.
[*] Set to 0 to revert to default XCOM behavior
[/list]
[*] [b]OverwatchRemovalMinimumDamage[/b] - Minimum damage required to cancel Overwatch, defaults to 1.
[*] [b]OverwatchRemovalMinimumHitChance[/b] - Minimum hit chance required to cancel Overwatch, defaults to 50.
[list]
[*] Both conditions have to be met to remove Overwatch.
[/list]
[/list]

[h1]Overrides[/h1]
This mod does not apply any hard overrides through XComGameEngine.ini.
We do selectively replace instances of the following classes with customized versions through code:
[list]
[*] X2AbilityToHitCalc_StandardAim
[*] X2Effect_ApplyWeaponDamage
[/list]

[h1]Incompatible mods[/h1]
If you experience issues with other mods, please let me know and I will update the list below.
[list]
[*] ( none so far )
[/list]

If you find any issues, please let me know in the comments.
