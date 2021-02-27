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
Look in the [url=http://steamcommunity.com/sharedfiles/filedetails/changelog/2409840472]Change Notes section[/url].

[h1]Installation directory[/h1]
This mod is installed to \SteamApps\workshop\content\268500\2409840472

[h1]Shot information[/h1]
If you are wondering why a certain shot did a certain amount of damage, be sure to first check your Launch.log file. It will contain a fairly detailed breakdown of every shot that was manipulated by this mod.
The log file is located here:
[code]%USERPROFILE%\Documents\My Games\XCOM2 War of the Chosen\XComGame\Logs\Launch.log[/code]
Search for <ReliableDamage.Damage> to find shot information written by the mod.

[h1]Configuration[/h1]
Configuration options can be set in Config\XComReliableDamage_WotC.ini.
That file also contains a full description of each option, so look there for more in depth information.
[list]
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
[*] [b]ApplyAmmoEffectsBasedOnHitChance[/b] - If set to 1 ammo effects like Dragon Rounds' Burning effect will not be applied on every hit (which is 100% in this mod) but will be applied on hit with a probability equal to the original hit chance.
[*] [b]ApplyVsTheLost[/b] - To disable all effects of this mod when targeting The Lost set this to 0.
[list]
[*] The Lost are relatively low HP so trading shot damage for a guaranteed hit is very powerful, especially combined with the "Headshot" ability that restores 1 action point when killing a Lost. It is therefore possible to disable all effects of this mod when targeting The Lost units by setting this option to 0.
[/list]
[*] [b]RemoveDamageSpread[/b] - Removes damage spread from weapons and abilities. 0 to retain all damage spread, 1 to remove.
[*] [b]RemoveOverwatchBasedOnHitChance[/b] - Set this option to 1 to remove Overwatch with a chance equal to the original hit chance, rather than 100% of the time (since shots do not miss anymore).
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
