class X2Effect_ApplyWeaponDamage_RD extends X2Effect_ApplyWeaponDamage;

var delegate<GetBonusEffectDamageValueDelegate> GetBonusEffectDamageValueFn;
var delegate<ModifyDamageValueDelegate> ModifyDamageValueFn;

delegate WeaponDamageValue GetBonusEffectDamageValueDelegate(XComGameState_Ability AbilityState, XComGameState_Unit SourceUnit, XComGameState_Item SourceWeapon, StateObjectReference TargetRef);
delegate bool ModifyDamageValueDelegate(out WeaponDamageValue DamageValue, Damageable Target, out array<Name> AppliedDamageTypes);

// Copies all properties from the given X2Effect_ApplyWeaponDamage
function Clone(X2Effect_ApplyWeaponDamage Source)
{
	// X2Effect
	TargetConditions = Source.TargetConditions;
	bApplyOnHit = Source.bApplyOnHit;
	bApplyOnMiss = Source.bApplyOnMiss;
	bApplyToWorldOnHit = Source.bApplyToWorldOnHit;
	bApplyToWorldOnMiss = Source.bApplyToWorldOnMiss;
	bUseSourcePlayerState = Source.bUseSourcePlayerState;
	ApplyChance = Source.ApplyChance;
	ApplyChanceFn = Source.ApplyChanceFn;
	MinStatContestResult = Source.MinStatContestResult;
	MaxStatContestResult = Source.MaxStatContestResult;
	MultiTargetStatContestInfo = Source.MultiTargetStatContestInfo;
	DamageTypes = Source.DamageTypes;
	bIsImpairing = Source.bIsImpairing;
	bIsImpairingMomentarily = Source.bIsImpairingMomentarily;
	bBringRemoveVisualizationForward = Source.bBringRemoveVisualizationForward;
	bShowImmunity = Source.bShowImmunity;
	bShowImmunityAnyFailure = Source.bShowImmunityAnyFailure;
	DelayVisualizationSec = Source.DelayVisualizationSec;
	bAppliesDamage = Source.bAppliesDamage;
	bCanBeRedirected = Source.bCanBeRedirected;
	OverrideMissMessage = Source.OverrideMissMessage;
	bHideDeathWorldMessage = Source.bHideDeathWorldMessage;	

	// X2Effect_ApplyWeaponDamage
	bExplosiveDamage = Source.bExplosiveDamage;
	bIgnoreBaseDamage = Source.bIgnoreBaseDamage;
	DamageTag = Source.DamageTag;
	bAlwaysKillsCivilians = Source.bAlwaysKillsCivilians;
	bApplyWorldEffectsForEachTargetLocation = Source.bApplyWorldEffectsForEachTargetLocation;
	bAllowFreeKill = Source.bAllowFreeKill;
	bAllowWeaponUpgrade = Source.bAllowWeaponUpgrade;
	bBypassShields = Source.bBypassShields;
	bIgnoreArmor = Source.bIgnoreArmor;
	bBypassSustainEffects = Source.bBypassSustainEffects;
	HideVisualizationOfResultsAdditional = Source.HideVisualizationOfResultsAdditional;
	EffectDamageValue = Source.EffectDamageValue;
	EnvironmentalDamageAmount = Source.EnvironmentalDamageAmount;

	// The Bonus effect (e.g. Shred) is actually a function,
	// so should be copied using a delegate
	GetBonusEffectDamageValueFn = Source.GetBonusEffectDamageValue;

	// This was added for Long War 2, Ranger's Double Barrel
	// uses this function so should be copied as well.
	ModifyDamageValueFn = Source.ModifyDamageValue;
}

function WeaponDamageValue GetBonusEffectDamageValue(XComGameState_Ability AbilityState, XComGameState_Unit SourceUnit, XComGameState_Item SourceWeapon, StateObjectReference TargetRef)
{
	// We call the stored delegate function of the Source (see Clone function)
	return GetBonusEffectDamageValueFn(AbilityState, SourceUnit, SourceWeapon, TargetRef);
}

simulated function bool ModifyDamageValue(out WeaponDamageValue DamageValue, Damageable Target, out array<Name> AppliedDamageTypes)
{
    // We call the stored delegate function of the Source (see Clone function)
	return ModifyDamageValueFn(DamageValue, Target, AppliedDamageTypes);
}

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local Damageable kNewTargetDamageableState;
	local int iDamage, iMitigated, NewRupture, NewShred, TotalToKill; 
	local XComGameState_Unit TargetUnit, SourceUnit;
	local XComGameState_Item SourceWeapon;
	local array<X2WeaponUpgradeTemplate> WeaponUpgradeTemplates;
	local X2WeaponUpgradeTemplate WeaponUpgradeTemplate;
	local array<Name> AppliedDamageTypes;
	local int bAmmoBypassesShields, bFullyImmune;
	local bool bDoesDamageIgnoreShields;
	local XComGameStateHistory History;
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local array<DamageModifierInfo> SpecialDamageMessages;
	local DamageResult ZeroDamageResult;

	// Reliable Damage locals
	local int iBaseHitChance, iModifiedHitChance, iAimAssistedHitChance, iFinalHitChance, iMissChance, iCritChance, iMinDamage, iMaxDamage, iMinRupture, iMaxRupture, iMinShred, iMaxShred, iDamageOnMiss, iCritDamage, iGrazeChance, iGrazeDamage, iArmor, iPierce, iEffectDmg, iRemainingArmor, PlayerID;
	local float fActualDamage, fActualShred, fActualRupture, fHitChance, fMissChance, fCritChance, fMaxDamageChance, fMaxRuptureChance, fMaxShredChance, fRolledValue, fGrazeChance;		
	local XComGameState_Ability Ability;
	local ShotBreakdown Breakdown;
	local ApplyDamageInfo DamageInfo;	
	local X2Effect_Persistent EffectTemplate;
	local EffectAppliedData TempAppliedData;
	local bool IsChainShot, IsXCom, IsAlien, ShotRemovesOverwatch;
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityToHitCalc_StandardAim_RD StandardAim_RD;
	local XComGameState_Player Player;
	local array<Name> CopyReservedActionPoints;	
	local EAbilityHitResult HitResult;

	// Config vars from StandardAim_RD
	local bool RoundingEnabled, KeepCrit, KeepGraze;
	local int OverwatchRemovalMinimumDamage, OverwatchRemovalMinimumHitChance;

	kNewTargetDamageableState = Damageable(kNewTargetState);
	if( kNewTargetDamageableState != none )
	{
		AppliedDamageTypes = DamageTypes;
		iDamage = CalculateDamageAmount(ApplyEffectParameters, iMitigated, NewRupture, NewShred, AppliedDamageTypes, bAmmoBypassesShields, bFullyImmune, SpecialDamageMessages, NewGameState);
		bDoesDamageIgnoreShields = (bAmmoBypassesShields > 0) || bBypassShields;

		// Start of Reliable Damage modifications

		// General note: iDamage does *not* include damage to armor.
		// This is already taken care of before. iDamage value is applied directly to HP + Shield.
		History = `XCOMHISTORY;
		SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
		TargetUnit = XComGameState_Unit(kNewTargetState);
		Ability = XComGameState_Ability(History.GetGameStateForObjectID(ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
		AbilityTemplate = Ability.GetMyTemplate();
		StandardAim_RD = X2AbilityToHitCalc_StandardAim_RD(AbilityTemplate.AbilityToHitCalc);
		PlayerID = SourceUnit.GetAssociatedPlayerID();
		Player = XComGameState_Player(History.GetGameStateForObjectID(PlayerID));
		IsXCom = Player.GetTeam() == eTeam_XCom;
		IsAlien = Player.GetTeam() == eTeam_Alien;
		HitResult = ApplyEffectParameters.AbilityResultContext.HitResult;

		// Config vars from StandardAim_RD
		if(StandardAim_RD != None)
		{
			RoundingEnabled = StandardAim_RD.RoundingEnabled;
			KeepCrit = StandardAim_RD.KeepCrit;
			KeepGraze = StandardAim_RD.KeepGraze;
			OverwatchRemovalMinimumDamage = StandardAim_RD.OverwatchRemovalMinimumDamage;
			OverwatchRemovalMinimumHitChance = StandardAim_RD.OverwatchRemovalMinimumHitChance;
		}

		// Get the ShotBreakdown for this shot, which includes all the probabilities of
		// hit / crit / etc.
		Ability.LookupShotBreakdown(Ability.OwnerStateObject, ApplyEffectParameters.TargetStateObjectRef, Ability.GetReference(), Breakdown);				

		// The Hit Chance can be above 100 (due to items / high level Snipers, etc).
		// We have to limit it at 100, otherwise we will apply more damage than we should
		// since we use it as a multiplier.
		iBaseHitChance = Min((Breakdown.bIsMultishot ? Breakdown.MultiShotHitChance : Breakdown.ResultTable[eHit_Success] + Breakdown.ResultTable[eHit_Crit] + Breakdown.ResultTable[eHit_Graze] ), 100);		

		// XCOM has several built-in ways to improve a player's hit chance (Aim Assist), invisible to the player.
		// We will use this modified hit chance as well if we can find it.
		// Aim Assist is not used on reaction shots, though.
		// Also, Aim Assist has a configurable maximum value. This is 95 by default, so we should make sure
		// NOT to apply Aim Assist if our base Hit Chance is already higher than that value, otherwise
		// our hit chance would actually decrease. This is only true if we are team XCom, since team Alien
		// actually gets a penalty from Aim Assist.
		if(StandardAim_RD != None && !StandardAim_RD.bReactionFire && (IsAlien || (IsXCom && iBaseHitChance < StandardAim_RD.MaxAimAssistScore)))
		{
			iModifiedHitChance = StandardAim_RD.GetModifiedHitChanceForCurrentDifficulty(Player, TargetUnit, iBaseHitChance);

			// In vanilla XCOM, the modified hit chance is only applied if the first shot (without the increased hit %)
			// was a miss (if XCom), or if it was a hit (if Alien)
			if(IsXCom)
			{
				// For XCom, the hit chance is slightly increased with Aim Assist
				// In regular XCOM, this meant an initially rolled miss could be turned into a hit
				// We incorporate this "second chance" into the hit chance by slightly increasing it
				// We recalculate the hit chance by weighting the modified hit chance into it with the miss %.
				iAimAssistedHitChance = Round(iBaseHitChance * (iBaseHitChance / 100.0) + iModifiedHitChance * (1.0 - iBaseHitChance / 100.0));
			}
			else // Alien
			{
				// For Alien, the modified Hit Chance leads to a lower hit chance, since it can turn an Alien Hit into a Miss
				// This decreased chance is applied on hit, rather than on miss.
				iAimAssistedHitChance = Round(iBaseHitChance * (1.0 - iBaseHitChance / 100.0) + iModifiedHitChance * (iBaseHitChance / 100.0));
			}

		}
		else
		{
			// Without StandardAim_RD to request the AimAssisted value, just use BaseHitChance
			iAimAssistedHitChance = iBaseHitChance;
		}

		// In this mod, Chain Shot will always fire twice which makes it slightly stronger than intended.
		// We have to fix the dealt damage by lowering the Hit Chance with a multiplier of exactly 1.0 - (fMissChance / 2).
		IsChainShot = Ability.GetMyTemplateName() == 'ChainShot' || Ability.GetMyTemplateName() == 'ChainShot2';

		if(IsChainShot)
		{
			fMissChance = 1.0 - (iAimAssistedHitChance / 100.0);
			iFinalHitChance = Round(iAimAssistedHitChance * (1.0 - fMissChance / 2.0));
		}
		else
		{
			iFinalHitChance = iAimAssistedHitChance;
		}

		// Sanity check, make sure not to go above 100% hit chance
		iFinalHitChance = Min(100, iFinalHitChance);

		// Calculate miss chance
		iMissChance = 100 - iFinalHitChance;
		fHitChance = iFinalHitChance / 100.0;
		fMissChance = 1.0 - fHitChance;

		`Log("");
		`Log("----- Reliable Damage: Apply Weapon Damage BEGIN -----");

		`Log("Source: " $ SourceUnit.GetName(eNameType_FullNick));
		// TargetUnit can be None, e.g. when targeting an objective that needs to be destroyed
		if(TargetUnit != None) `Log("Target: " $ TargetUnit.GetName(eNameType_FullNick));
		`Log("Ability: " $ Ability.GetMyTemplateName());
		`Log("Hit Result: " $ HitResult);		
		`Log("Hit Chance: " $ iBaseHitChance $ "%");
		if(iAimAssistedHitChance != iBaseHitChance)
		{
			`Log("Hit Chance modified by Aim Assist to " $ iAimAssistedHitChance $ "%");
		}
		if(IsChainShot)
		{
			`Log("Hit Chance has been corrected to " $ iFinalHitChance $ "%" $ " to fix Chain Shot damage");
		}
		`Log("Damage by XCOM: " $ iDamage, iDamage > 0);
		`Log("Rupture by XCOM: " $ NewRupture, NewRupture > 0);
		`Log("Shred by XCOM: " $ NewShred, NewShred > 0);

		// Damage on miss.
		// This incorporates the effect of the Stock Weapon Attachment.
		// It simply increases the actual damage by [miss percentage] * [damage on miss].
		// Note the damage is added *after* XCOM has already considered armor effects.
		// This is exactly how it works in the base game, if you have dmg on miss and you miss
		// on a unit that has armor, the armor is never touched, it goes directly to HP or shield.
		SourceWeapon = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.ItemStateObjectRef.ObjectID));
		if(SourceWeapon != None)
		{
			WeaponUpgradeTemplates = SourceWeapon.GetMyWeaponUpgradeTemplates();
			foreach WeaponUpgradeTemplates(WeaponUpgradeTemplate)
			{
				if(WeaponUpgradeTemplate.BonusDamage.Tag == name("Miss"))
				{
					iDamageOnMiss += WeaponUpgradeTemplate.BonusDamage.Damage;
				}
			}

			`Log("Damage on Miss: " $ iDamageOnMiss, iDamageOnMiss > 0);
		}

		// Graze chance
		// We adjust the actual damage based on the graze chance and the GRAZE_DMG_MULT, which
		// is the configurable multiplier from the base game that is used to calculate the graze damage.
		// The damage is always reduced overall if a unit has a graze chance > 0.
		// This is done since we also remove the Graze shot itself because it was very random, not allowing the player
		// to make reliable decisions based on damage.
		// Lowering the damage on all standard shots has the same expected value of damage reduction overall
		// as the regular Graze, but is just less random.
		// Graze chance is taken from the ShotBreakdown of this shot
		
		// If Graze Shots can still occur, do not incorporate any Graze Chance and Damage into regular shots
		if(KeepGraze)
		{
			iGrazeChance = 0;
		}
		else
		{
			iGrazeChance = Breakdown.ResultTable[eHit_Graze];
		}
		
		fGrazeChance = iGrazeChance / 100.0;

		if(iGrazeChance > 0)
		{
			// The Graze "damage" is actually a negative number, as 
			// a graze shot deals less damage than a regular shot.
			iGrazeDamage = (iDamage * GRAZE_DMG_MULT) - iDamage;

			`Log("Graze Chance: " $ fGrazeChance);		
			`Log("Graze Damage: " $ iGrazeDamage);	
		}

		// Critical Damage
		// If Crit Shots can still occur, do not incorporate Crit Chance / Damage in regular shots
		if(KeepCrit)
		{
			iCritChance = 0;
		}
		else 
		{
			iCritChance = Breakdown.ResultTable[eHit_Crit];
		}

		// This function should fill DamageInfo with Crit / Pierce values
		if(TargetUnit != None)
		{
			CalculateDamageValues(SourceWeapon, SourceUnit, TargetUnit, Ability, DamageInfo, AppliedDamageTypes);
		}

		// Pierce
		iPierce =
			SourceUnit.GetCurrentStat(eStat_ArmorPiercing) +
			DamageInfo.BaseDamageValue.Pierce +
			DamageInfo.ExtraDamageValue.Pierce +
			DamageInfo.BonusEffectDamageValue.Pierce +
			DamageInfo.AmmoDamageValue.Pierce +
			DamageInfo.UpgradeDamageValue.Pierce;

		// Pierce from source unit "Effects"
		// Actually this is where A.P. Rounds finally get added, apparently it is modeled as an effect on
		// the source unit? I would have expected it to set on the AmmoDamageValue (see above).
		if(SourceUnit != None)
		{
			//  Allow attacker effects to modify damage output before applying final bonuses and reductions
			foreach SourceUnit.AffectedByEffects(EffectRef)
			{
				EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
				EffectTemplate = EffectState.GetX2Effect();
				iEffectDmg = EffectTemplate.GetExtraArmorPiercing(EffectState, SourceUnit, TargetUnit, Ability, TempAppliedData);
				if (iEffectDmg != 0)
				{
					iPierce += iEffectDmg;
				}
			}
		}

		`Log("Pierce: " $ iPierce, iPierce > 0);

		// We need the Armor
		if(TargetUnit != None)
		{
			iArmor = TargetUnit.GetArmorMitigationForUnitFlag();

			// If the attack pierces armor, subtract the pierced amount from the armor
			// Make sure we do not set armor lower than 0
			iArmor = Max(iArmor - iPierce, 0);

			// If this attack ignores armor, set armor to 0.
			if(bIgnoreArmor)
			{
				iArmor = 0;
			}
		}

		if(iCritChance > 0)
		{
			// If the Target had any Armor that has not mitigated any damage,
			// it has to mitigate the Crit Damage first. We add the pierced armor to the mitigated armor,
			// since pierced armor does not count towards mitigated, and we do not want to reduce critical
			// damage by the pierced armor.
			// This is probably fairly rare, since it means the original damage
			// had to be less than the amount of armor of the target, but when the Crit Chance is > 0,
			// the Hit Chance is generally very high anyway so we should have dealt quite some damage.
			// However, with Pistols this can happen, especially low level pistols and high armor values.
			iRemainingArmor = Max(iArmor - (iMitigated + iPierce), 0);

			// Any remaining armor points are then deducted from the Critical Damage,
			// as explained above. Make sure we do not go sub zero.
			iCritDamage =
				DamageInfo.BaseDamageValue.Crit +
				DamageInfo.ExtraDamageValue.Crit +
				DamageInfo.BonusEffectDamageValue.Crit +
				DamageInfo.AmmoDamageValue.Crit +
				DamageInfo.UpgradeDamageValue.Crit;

			// Gather all Crit damage applied by effects such as Talon Rounds
			if(SourceUnit != None)
			{
				// We are looking for bonus damage to Crit
				TempAppliedData.AbilityResultContext.HitResult = eHit_Crit;

				//  Allow attacker effects to modify damage output before applying final bonuses and reductions
				foreach SourceUnit.AffectedByEffects(EffectRef)
				{
					EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
					EffectTemplate = EffectState.GetX2Effect();

					iEffectDmg = EffectTemplate.GetAttackingDamageModifier(EffectState, SourceUnit, Damageable(TargetUnit), Ability, TempAppliedData, iDamage);

					if(iEffectDmg > 0)
					{
						iCritDamage += iEffectDmg;
					}
				}
			}

			iCritDamage = Max(iCritDamage - iRemainingArmor, 0);
			fCritChance = iCritChance / 100.0;

			`Log("Crit Chance: " $ iCritChance $ "%");
			`Log("Crit Damage: " $ iCritDamage);
		}

		// iCritDamage is only the *additional* damage on top of the iDamage, which is why we do not
		// multiply it by fHitChance again. It is more a less a separate entity with its own chance to occur.
		fActualDamage  = fHitChance * iDamage + fCritChance * iCritDamage + fGrazeChance * iGrazeDamage + fMissChance * iDamageOnMiss;
		fActualShred   = fHitChance * NewShred;
		fActualRupture = fHitChance * NewRupture;

		`Log("Actual Damage: " $ fActualDamage $ " (" $ iFinalHitChance $ "% of " $ iDamage $
			((iCritChance > 0 && iCritDamage > 0) ? " + " $ iCritChance $ "% of " $ iCritDamage : "") $
			(iDamageOnMiss > 0 ? " + " $ iMissChance $ "% of " $ iDamageOnMiss : "") $
			(iGrazeChance > 0 ? " + " $ iGrazeChance $ "% of " $ iGrazeDamage : "") $			
			")", iDamage > 0);
		`Log("Actual Shred: " $ fActualShred $ " (" $ iFinalHitChance $ "% of " $ NewShred $ ")", NewShred > 0);
		`Log("Actual Rupture: " $ fActualRupture $ " (" $ iFinalHitChance $ "% of " $ NewRupture $ ")", NewRupture > 0);

		if(RoundingEnabled)
		{
			iDamage = Round(fActualDamage);
			NewRupture = Round(fActualRupture);
			NewShred = Round(fActualShred);

			`Log("Damage rounded to " $ iDamage);
		}
		else
		{
			iMinDamage = FFloor(fActualDamage);
			iMaxDamage = FCeil(fActualDamage);

			iMinRupture = FFloor(fActualRupture);
			iMaxRupture = FCeil(fActualRupture);

			iMinShred = FFloor(fActualShred);
			iMaxShred = FCeil(fActualShred);

			// Example: 4 dmg, 60% shot (fActualDamage: 2.4)
			// Damage is between 2 and 3, we have to calculate the
			// chance for both values. This is propertional to the fActualDamage.
			// Thus; chance for 2 is 60%, chance for 3 is 40% (in this example).
			// We can get those chances by looking at the decimal part of fActualDamage.
			fMaxDamageChance = fActualDamage - iMinDamage;
			fMaxShredChance = fActualShred - iMinShred;
			fMaxRuptureChance = fActualRupture - iMinRupture;

			`Log(
				"Min Damage: " $ iMinDamage $ " (" $ Round((1.0 - fMaxDamageChance) * 100.0) $ "%), " $
				"Max Damage: " $ iMaxDamage $ " (" $ Round(fMaxDamageChance * 100.0) $ "%)",
				iDamage > 0
			);

			`Log(
				"Min Rupture: " $ iMinRupture $ " (" $ Round((1.0 - fMaxRuptureChance) * 100.0) $ "%), " $
				"Max Rupture: " $ iMaxRupture $ " (" $ Round(fMaxRuptureChance * 100.0) $ "%)",
				iMaxRupture > 0
			);

			`Log(
				"Min Shred: " $ iMinShred $ " (" $ Round((1.0 - fMaxShredChance) * 100.0) $ "%), " $
				"Max Shred: " $ iMaxShred $ " (" $ Round(fMaxShredChance * 100.0) $ "%)",
				iMaxShred > 0
			);

			// Roll for a value and based on the result, pick the damage
			// SYNC_RAND returns an integer 0-100 (not 100 itself), we want a float 0.0-1.0 (not 1.0 itself)
			fRolledValue = `SYNC_RAND(100) / 100.0;
			iDamage = fRolledValue < fMaxDamageChance ? iMaxDamage : iMinDamage;

			// Roll again for Rupture
			fRolledValue = `SYNC_RAND(100) / 100.0;
			NewRupture = fRolledValue < fMaxRuptureChance ? iMaxRupture : iMinRupture;

			// And finally for Shred
			fRolledValue = `SYNC_RAND(100) / 100.0;
			NewShred = fRolledValue < fMaxShredChance ? iMaxShred : iMinShred;
		}

		`Log("Applied Damage: " $ iDamage);
		`Log("Applied Rupture: " $ NewRupture, iMaxRupture > 0);
		`Log("Applied Shred: " $ NewShred, iMaxShred > 0);

		`Log("----- Reliable Damage: Apply Weapon Damage END -----");
		`Log("");

		// End of Reliable Damage modifications

		if ((iDamage == 0) && (iMitigated == 0) && (NewRupture == 0) && (NewShred == 0))
		{
			// No damage is being dealt
			if (SpecialDamageMessages.Length > 0 || bFullyImmune != 0)
			{
				TargetUnit = XComGameState_Unit(kNewTargetState);
				if (TargetUnit != none)
				{
					ZeroDamageResult.bImmuneToAllDamage = bFullyImmune != 0;
					ZeroDamageResult.Context = NewGameState.GetContext();
					ZeroDamageResult.SourceEffect = ApplyEffectParameters;
					ZeroDamageResult.SpecialDamageFactors = SpecialDamageMessages;
					TargetUnit.DamageResults.AddItem(ZeroDamageResult);
				}
			}
			return;
		}

		if (bAllowFreeKill)
		{
			//  check to see if the damage ought to kill them and if not, roll for a free kill
			TargetUnit = XComGameState_Unit(kNewTargetState);
			if (TargetUnit != none)
			{
				TotalToKill = TargetUnit.GetCurrentStat(eStat_HP) + TargetUnit.GetCurrentStat(eStat_ShieldHP);
				if (TotalToKill > iDamage)
				{
					History = `XCOMHISTORY;
					//  check weapon upgrades for a free kill
					SourceWeapon = XComGameState_Item(History.GetGameStateForObjectID(ApplyEffectParameters.ItemStateObjectRef.ObjectID));
					if (SourceWeapon != none)
					{
						WeaponUpgradeTemplates = SourceWeapon.GetMyWeaponUpgradeTemplates();
						foreach WeaponUpgradeTemplates(WeaponUpgradeTemplate)
						{
							if (WeaponUpgradeTemplate.FreeKillFn != none && WeaponUpgradeTemplate.FreeKillFn(WeaponUpgradeTemplate, TargetUnit))
							{
								TargetUnit.TakeEffectDamage(self, TotalToKill, 0, NewShred, ApplyEffectParameters, NewGameState, false, false, true, AppliedDamageTypes, SpecialDamageMessages);
								if (TargetUnit.IsAlive())
								{
									`RedScreen("Somehow free kill upgrade failed to kill the target! -jbouscher @gameplay");
								}
								else
								{
									TargetUnit.DamageResults[TargetUnit.DamageResults.Length - 1].bFreeKill = true;
								}
								return;
							}
						}
					}
					//  check source unit effects for a free kill
					SourceUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
					if (SourceUnit == none)
						SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));

					foreach SourceUnit.AffectedByEffects(EffectRef)
					{
						EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
						if (EffectState != none)
						{
							if (EffectState.GetX2Effect().FreeKillOnDamage(SourceUnit, TargetUnit, NewGameState, TotalToKill, ApplyEffectParameters))
							{
								TargetUnit.TakeEffectDamage(self, TotalToKill, 0, NewShred, ApplyEffectParameters, NewGameState, false, false, true, AppliedDamageTypes, SpecialDamageMessages);
								if (TargetUnit.IsAlive())
								{
									`RedScreen("Somehow free kill effect failed to kill the target! -jbouscher @gameplay");
								}
								else
								{
									TargetUnit.DamageResults[TargetUnit.DamageResults.Length - 1].bFreeKill = true;
									TargetUnit.DamageResults[TargetUnit.DamageResults.Length - 1].FreeKillAbilityName = EffectState.ApplyEffectParameters.AbilityInputContext.AbilityTemplateName;
								}
								return;
							}
						}
					}
				}
			}
		}
		
		if (NewRupture > 0)
		{
			kNewTargetDamageableState.AddRupturedValue(NewRupture);
		}

		// Reliable Damage modifications ->
		// We want to keep Overwatch active in some situations
		ShotRemovesOverwatch = iDamage >= OverwatchRemovalMinimumDamage && iBaseHitChance >= OverwatchRemovalMinimumHitChance;

		if(!ShotRemovesOverwatch)
		{
			if(TargetUnit == None)
			{
				TargetUnit = XComGameState_Unit(kNewTargetState);
			}

			if(TargetUnit != None)
			{
				CopyReservedActionPoints = TargetUnit.ReserveActionPoints;
			}
		}
		// <- Reliable Damage modifications

		kNewTargetDamageableState.TakeEffectDamage(self, iDamage, iMitigated, NewShred, ApplyEffectParameters, NewGameState, false, true, bDoesDamageIgnoreShields, AppliedDamageTypes, SpecialDamageMessages);

		// Reliable Damage modifications ->
		if(!ShotRemovesOverwatch)
		{
			// Restore Overwatch
			if(TargetUnit != None && TargetUnit.ReserveActionPoints.Length != CopyReservedActionPoints.Length)
			{
				TargetUnit.ReserveActionPoints = CopyReservedActionPoints;
			}
		}
		// <- Reliable Damage modifications
	}
}                                  
                                    
simulated function GetDamagePreview(StateObjectReference TargetRef, XComGameState_Ability AbilityState, bool bAsPrimaryTarget, out WeaponDamageValue MinDamagePreview, out WeaponDamageValue MaxDamagePreview, out int AllowsShield)
{
	local ShotBreakdown Breakdown;
	local float fHitChance, fMissChance, fCritChance, fActualMinDamage, fActualMaxDamage, fActualMinRupture, fActualMaxRupture, fActualMinShred, fActualMaxShred, fGrazeChance;
	local XComGameState_Unit SourceUnit, TargetUnit;
	local int iHitChance, iModifiedHitChance, iMinArmor, iMaxArmor, iDamageOnMiss, iCritChance, iGrazeChance, iMinGrazeDamage, iMaxGrazeDamage, iRupture, iMinCritDamage, iMaxCritDamage, iMinDamage, iMaxDamage, PlayerID;
	local XComGameStateHistory History;
	local XComGameState_Item SourceWeapon;
	local array<X2WeaponUpgradeTemplate> WeaponUpgradeTemplates;
	local X2WeaponUpgradeTemplate WeaponUpgradeTemplate;
	local ApplyDamageInfo DamageInfo;
	local array<Name> AppliedDamageTypes;
	local XComGameState_Effect EffectState;
	local StateObjectReference EffectRef;
	local X2Effect_Persistent EffectTemplate;
	local EffectAppliedData TempAppliedData;
	local X2AbilityToHitCalc_StandardAim_RD StandardAim_RD;	
	local XComGameState_Player Player;
	local X2AbilityTemplate AbilityTemplate;
	local bool IsXCom, IsAlien, RoundingEnabled, KeepCrit, KeepGraze;

	// Default behavior
	super.GetDamagePreview(TargetRef, AbilityState, bAsPrimaryTarget, MinDamagePreview, MaxDamagePreview, AllowsShield);

	History = `XCOMHISTORY;
	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));
	PlayerID = SourceUnit.GetAssociatedPlayerID();
	Player = XComGameState_Player(History.GetGameStateForObjectID(PlayerID));	
	TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(TargetRef.ObjectID));
	IsXCom = Player.GetTeam() == eTeam_XCom;
	IsAlien = Player.GetTeam() == eTeam_Alien;
	AbilityTemplate = AbilityState.GetMyTemplate();
	StandardAim_RD = X2AbilityToHitCalc_StandardAim_RD(AbilityTemplate.AbilityToHitCalc);

	if(StandardAim_RD != None)
	{
		RoundingEnabled = StandardAim_RD.RoundingEnabled;
		KeepCrit = StandardAim_RD.KeepCrit;
		KeepGraze = StandardAim_RD.KeepGraze;
	}

	// Get Hit Chance
	AbilityState.LookupShotBreakdown(AbilityState.OwnerStateObject, TargetRef, AbilityState.GetReference(), Breakdown);
	iHitChance = Min((Breakdown.bIsMultishot ? Breakdown.MultiShotHitChance : Breakdown.ResultTable[eHit_Success] + Breakdown.ResultTable[eHit_Crit] + Breakdown.ResultTable[eHit_Graze] ), 100);

	// Aim Assist changes the hit chance
	if(StandardAim_RD != None && !StandardAim_RD.bReactionFire && (IsAlien || (IsXCom && iHitChance < StandardAim_RD.MaxAimAssistScore)))
	{			
		iModifiedHitChance = StandardAim_RD.GetModifiedHitChanceForCurrentDifficulty(Player, TargetUnit, iHitChance);		

		// In vanilla XCOM, the modified hit chance is only applied if the first shot (without the increased hit %)
		// was a miss (if XCom), or if it was a hit (if Alien)
		if(IsXCom)
		{
			// For XCom, the hit chance is slightly increased with Aim Assist
			// In regular XCOM, this meant an initially rolled miss could be turned into a hit
			// We incorporate this "second chance" into the hit chance by slightly increasing it
			// We recalculate the hit chance by weighting the modified hit chance into it with the miss %.
			iHitChance = Round(iHitChance * (iHitChance / 100.0) + iModifiedHitChance * (1.0 - iHitChance / 100.0));
		}
		else // Alien
		{
			// For Alien, the modified Hit Chance leads to a lower hit chance, since it can turn an Alien Hit into a Miss
			// This decreased chance is applied on hit, rather than on miss.
			iHitChance = Round(iHitChance * (1.0 - iHitChance / 100.0) + iModifiedHitChance * (iHitChance / 100.0));
		}
	}

	// In this mod, Chain Shot will always fire twice which makes it slightly stronger than intended.
	// We have to fix the dealt damage by lowering the Hit Chance with a multiplier of exactly 1 - (miss_chance / 2).
	if(AbilityState.GetMyTemplateName() == 'ChainShot' || AbilityState.GetMyTemplateName() == 'ChainShot2')
	{
		fMissChance = 1.0 - (iHitChance / 100.0);
		iHitChance = Round(iHitChance * (1.0 - fMissChance / 2.0));
	}

	fHitChance = iHitChance / 100.0;
	fMissChance = FMax(0.0, 1.0 - fHitChance);	

	if(TargetUnit != None)
	{
		// Min and max armor start out at the target's armor value
		// Due to (possibly) different min and max piercing values this can change later
		iMinArmor = TargetUnit.GetArmorMitigationForUnitFlag();
		iMaxArmor = iMinArmor;

		// If the ability ignores armor, set armor to 0
		if(bIgnoreArmor)
		{
			iMinArmor = 0;
			iMaxArmor = 0;
		}

		// In the final preview (compiled *after* this function),
		// XCOM seems to just add the Rupture amount on the target
		// to the {Min,Max}DamagePreview.Damage values. Since we
		// also scale this bonus damage by the hit chance like everything else
		// this will lead to incorrect preview damage values on Ruptured targets.
		// To prevent this, we have to incorporate the actual Rupture bonus damage into
		// our calculation, and subtract the plain Rupture value since XCOM will add that again afterwards,
		// so we cancel that effect.
		iRupture = TargetUnit.GetRupturedValue();
	}	

	// If the attacker pierces a certain amount of armor, subtract it here
	// Make sure armor does not go below 0
	iMinArmor = Max(iMinArmor - MinDamagePreview.Pierce, 0);
	iMaxArmor = Max(iMaxArmor - MaxDamagePreview.Pierce, 0);

	// Some abilities ignore armor (all of it I suppose?),
	// so in that case the armor is effectively 0.
	if(AbilityState.DamageIgnoresArmor())
	{
		iMinArmor = 0;
		iMaxArmor = 0;
	}

	// Damage on miss.
	// This incorporates the effect of the Stock Weapon Attachment.
	// It simply increases the actual damage by the miss percentage.
	if (AbilityState.SourceAmmo.ObjectID > 0)
	{
		SourceWeapon = AbilityState.GetSourceAmmo();
	}
	else
	{
		SourceWeapon = AbilityState.GetSourceWeapon();
	}

	if(SourceWeapon != None)
	{
		WeaponUpgradeTemplates = SourceWeapon.GetMyWeaponUpgradeTemplates();
		foreach WeaponUpgradeTemplates(WeaponUpgradeTemplate)
		{
			if(WeaponUpgradeTemplate.BonusDamage.Tag == name("Miss"))
			{
				iDamageOnMiss += WeaponUpgradeTemplate.BonusDamage.Damage;
			}
		}
	}

	// Critical Damage
	if(KeepCrit)
	{
		iCritChance = 0;
	}
	else
	{
		iCritChance = Breakdown.ResultTable[eHit_Crit];
	}

	fCritChance = iCritChance / 100.0;

	if(iCritChance > 0)
	{
		if(TargetUnit != None)
		{
			CalculateDamageValues(SourceWeapon, SourceUnit, TargetUnit, AbilityState, DamageInfo, AppliedDamageTypes);
		}

		iMinCritDamage =
			DamageInfo.BaseDamageValue.Crit +
			DamageInfo.ExtraDamageValue.Crit +
			DamageInfo.BonusEffectDamageValue.Crit +
			DamageInfo.AmmoDamageValue.Crit +
			DamageInfo.UpgradeDamageValue.Crit;

		iMaxCritDamage = iMinCritDamage;

		// Talon Rounds Crit bonus damage, and possibly others
		if(SourceUnit != None)
		{
			// We are looking at Crit bonus
			TempAppliedData.AbilityResultContext.HitResult = eHit_Crit;

			//  Allow attacker effects to modify damage output before applying final bonuses and reductions
			foreach SourceUnit.AffectedByEffects(EffectRef)
			{
				EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
				EffectTemplate = EffectState.GetX2Effect();

				iMinCritDamage += EffectTemplate.GetAttackingDamageModifier(EffectState, SourceUnit, Damageable(TargetUnit), AbilityState, TempAppliedData, MinDamagePreview.Damage);
				iMaxCritDamage += EffectTemplate.GetAttackingDamageModifier(EffectState, SourceUnit, Damageable(TargetUnit), AbilityState, TempAppliedData, MaxDamagePreview.Damage);
			}
		}

		// If the regular damage does not go through all armor,
		// we have to reduce the crit damage by whatever armor remained
		// but not go below 0, of course.
		iMinCritDamage = Max(0, iMinCritDamage - Max(0, iMinArmor - (MinDamagePreview.Damage + iRupture)));
		iMaxCritDamage = Max(0, iMaxCritDamage - Max(0, iMaxArmor - (MaxDamagePreview.Damage + iRupture)));
	}

	// XCOM will actually never yield 0 damage, even if a unit has more armor points
	// then the damage we deal. It will then pass 1 damage instead, so account for this
	// by adjusting the damage valeus to be at least 1.
	iMinDamage = Max(1, MinDamagePreview.Damage + iRupture - iMinArmor);
	iMaxDamage = Max(1, MaxDamagePreview.Damage + iRupture - iMaxArmor);

	// Grazes
	// A graze hit deals partial damage, based on a multiplier that is applied to regular (i.e., not crit) damage.		
	if(KeepGraze)
	{
		iGrazeChance = 0;
	}
	else
	{
		iGrazeChance = Breakdown.ResultTable[eHit_Graze];
	}
	
	fGrazeChance = iGrazeChance / 100.0;	

	// Note the Graze damage is actually negative, since we work with delta values compared to the base damage of a shot.
	iMinGrazeDamage = (iMinDamage * GRAZE_DMG_MULT) - iMinDamage;
	iMaxGrazeDamage = (iMaxDamage * GRAZE_DMG_MULT) - iMaxDamage;

	// Actual minimum and maximum values for damage / rupture / shred
	// Regular Damage gets reduced by armor, Damage on Miss does *not*.
	// We do *NOT* show the damage absorbed by Armor in the preview, but only damage done to HP and Shield.
	// XCOM by default does show the damage absorbed by Armor, but this is only confusing, especially when you have
	// armor piercing items (e.g. A.P. rounds) and have to remember to this and do the math yourself.
	// With this preview, you always know the damage that will be done to HP / Shield without any effort on your part.	
	fActualMinDamage = fHitChance * iMinDamage + fCritChance * iMinCritDamage + fGrazeChance * iMinGrazeDamage + fMissChance * iDamageOnMiss;
	fActualMaxDamage = fHitChance * iMaxDamage + fCritChance * iMaxCritDamage + fGrazeChance * iMaxGrazeDamage + fMissChance * iDamageOnMiss;

	fActualMinRupture = fHitChance * MinDamagePreview.Rupture;
	fActualMaxRupture = fHitChance * MaxDamagePreview.Rupture;

	fActualMinShred = fHitChance * MinDamagePreview.Shred;
	fActualMaxShred = fHitChance * MaxDamagePreview.Shred;

	if(RoundingEnabled)
	{
		MinDamagePreview.Damage = Round(fActualMinDamage);
		MaxDamagePreview.Damage = Round(fActualMaxDamage);

		MinDamagePreview.Rupture = Round(fActualMinRupture);
		MaxDamagePreview.Rupture = Round(fActualMaxRupture);

		MinDamagePreview.Shred = Round(fActualMinShred);
		MaxDamagePreview.Shred = Round(fActualMaxShred);
	}
	else
	{
		// Without rounding we will calculate the delivered damage
		// based on the actual damage. The possible value is between
		// Floor(min) and Ceil(max). See explanation in XComReliableDamage.ini
		// The actual calculation is done in OnEffectAdded()
		// The XCOM UI will remove armor from the number provided here,
		// but we have already done that. So add the armor back so the preview
		// UI will be correct (the preview of HP blocks that will be removed from an Alien).
		// We again make sure we will pass at least 1, since XCOM flips out when it receives 0 in the preview
		MinDamagePreview.Damage = Max(1, FFloor(fActualMinDamage) + iMinArmor);
		MaxDamagePreview.Damage = Max(1, FCeil(fActualMaxDamage) + iMaxArmor);

		MinDamagePreview.Rupture = FFloor(fActualMinRupture);
		MaxDamagePreview.Rupture = FCeil(fActualMaxRupture);

		MinDamagePreview.Shred = FFloor(fActualMinShred);
		MaxDamagePreview.Shred = FCeil(fActualMaxShred);

		// We show the actual fractional numbers in our modified HUD.
		// The numbers are passed via properties on StandardAim_RD
		StandardAim_RD.MinDamage = fActualMinDamage;
		StandardAim_RD.MaxDamage = fActualMaxDamage;
	}

	// As explained above, XCOM seems to add the plain Rupture value
	// to the given {Min,Max}DamagePreview.Damage values above, so
	// these are actually not the final numbers displayed in the UI,
	// which is strange. Anyway, we have already incorporated bonus Rupture
	// damage (scaled by Hit Chance), so we have to counter the Rupture damage XCOM
	// will add after this function has returned, by subtracting that value here.
	MinDamagePreview.Damage -= iRupture;
	MaxDamagePreview.Damage -= iRupture;

	// We pass the actual fractional numbers to our modified HUD.
	// The numbers are passed via properties on StandardAim_RD
	// If rounding is enabled, the HUD will round them and display
	// them as whole numbers rather than as floats.
	StandardAim_RD.MinDamage = fActualMinDamage;
	StandardAim_RD.MaxDamage = fActualMaxDamage;
}

// Without this override we get 2 damage tooltips when firing at a Destructible Object like an Alien Relay												
simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, name EffectApplyResult)
{
	local XComGameState_Destructible Destructible;

	// For unknown reasons, firing at a Destructible with my modified ApplyWeaponDamage
	// caused 2 "X Damage" Message Boxes to appear instead of one.
	// To fix that, we don't do anything when this function triggered with a Destructible.
	// It is unknown what causes the other Message Box, but this does fix it.
	// Damage application itself works fine (applied only once), the issue is only with
	// the message boxes that appear.
	// We look at the OldState, since a destroyed object is not Targetable anymore but
	// we specifically look at that property.
	Destructible = XComGameState_Destructible(ActionMetadata.StateObject_OldState);
	if(Destructible != None && Destructible.IsTargetable())
	{
		return;
	}

	// In all other cases, use the default behavior.
	super.AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);
}