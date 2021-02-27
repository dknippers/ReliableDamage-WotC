class X2Effect_ApplyWeaponDamage_RD extends X2Effect_ApplyWeaponDamage;

var const Configuration Configuration;

var X2Effect_ApplyWeaponDamage Original;

struct AbilityGameStateContext
{
	var XComGameState_Ability Ability;
	var XComGameState_Unit SourceUnit;
	var XComGameState_Item SourceWeapon;
	var XComGameState_BaseObject TargetObject;
	var XComGameState_Unit TargetUnit;
};

struct WeaponDamage
{
	var int Damage;
	var int ArmorMitigation;
	var float HitChance;
};

// Copies all properties from the given X2Effect_ApplyWeaponDamage
function Clone(X2Effect_ApplyWeaponDamage Source)
{
	Original = Source;

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
}

function WeaponDamageValue GetBonusEffectDamageValue(XComGameState_Ability AbilityState, XComGameState_Unit SourceUnit, XComGameState_Item SourceWeapon, StateObjectReference TargetRef)
{
	return Original.GetBonusEffectDamageValue(AbilityState, SourceUnit, SourceWeapon, TargetRef);
}

simulated function bool ModifyDamageValue(out WeaponDamageValue DamageValue, Damageable Target, out array<Name> AppliedDamageTypes)
{
	return Original.ModifyDamageValue(DamageValue, Target, AppliedDamageTypes);
}

simulated function int CalculateDamageAmount(const out EffectAppliedData ApplyEffectParameters, out int ArmorMitigation, out int NewRupture, out int NewShred, out array<Name> AppliedDamageTypes, out int bAmmoIgnoresShields, out int bFullyImmune, out array<DamageModifierInfo> SpecialDamageMessages, optional XComGameState NewGameState)
{
	local int iTotalDamage, iDamageOnHit, iDamageOnMiss, iDamageOnCrit, iArmorPiercing, iArmor, iShield;
	local float fHitChance, fMissChance, fCritChance, fGrazeChance, fTotalDamage, fTotalArmorMitigation, fShred, fRupture;
	local AbilityGameStateContext AbilityContext;
	local ApplyDamageInfo DamageInfo;
	local array<float> PlusOneDamage;

	// Calculate damage as usual
	iDamageOnHit = super.CalculateDamageAmount(ApplyEffectParameters, ArmorMitigation, NewRupture, NewShred, AppliedDamageTypes, bAmmoIgnoresShields, bFullyImmune, SpecialDamageMessages, NewGameState);

	if(
		ApplyEffectParameters.AbilityResultContext.HitResult != eHit_Success ||
		(!Configuration.ApplyVsTheLost && UnitIsTheLost(ApplyEffectParameters.TargetStateObjectRef))
	)
	{
		// Do not modify in this scenario, just return value from super.
		return iDamageOnHit;
	}

	iDamageOnHit += ArmorMitigation;
	ArmorMitigation = 0;

	AbilityContext = GetAbilityContext(ApplyEffectParameters.AbilityStateObjectRef, ApplyEffectParameters.TargetStateObjectRef, NewGameState);
	DamageInfo = CalculateDamageInfo(AbilityContext);

	iShield = AbilityContext.TargetUnit != None ? AbilityContext.TargetUnit.GetCurrentStat(eStat_ShieldHP) : 0.0f;
	iArmorPiercing = GetArmorPiercing(AbilityContext, DamageInfo);
	iArmor = bIgnoreArmor ? 0 : GetArmorMitigation(ApplyEffectParameters.TargetStateObjectRef, iArmorPiercing);

	fHitChance = GetHitChance(AbilityContext.Ability, ApplyEffectParameters.TargetStateObjectRef, fCritChance, fGrazeChance);
	fMissChance = 1.0f - fHitChance;

	iDamageOnMiss = GetDamageOnMiss(AbilityContext.Ability);
	iDamageOnCrit = GetDamageOnCrit(AbilityContext, DamageInfo);
	PlusOneDamage = GetPlusOneDamage(DamageInfo);

	`Log("");
	`Log("<ReliableDamage.Damage>");
	`Log("");

	// Source
	LogUnit("Source:", AbilityContext.SourceUnit);
	LogAbility("Ability:", AbilityContext.Ability);
	if(AbilityContext.SourceWeapon != None) LogItem("Weapon:", AbilityContext.SourceWeapon);

	// Target
	if(AbilityContext.TargetUnit != None) LogUnit("Target:", AbilityContext.TargetUnit);
	else if(AbilityContext.TargetObject != None) `Log("Target:" @ AbilityContext.TargetObject.Class);
	LogInt("Shield:", iShield, iShield != 0);
	LogInt("Armor:", iArmor, iArmor != 0);

	// Damage
	`Log("PlusOneDamage:" @ "0-" $ PlusOneDamage.Length, PlusOneDamage.Length > 0);
	LogHitChance("HitChance:", fHitChance);

	CalculateExpectedDamageAndArmorMitigation(fHitChance, fMissChance, fCritChance, fGrazeChance, iDamageOnHit, iDamageOnMiss, iDamageOnCrit, PlusOneDamage, iShield, iArmor, fTotalDamage, fTotalArmorMitigation, true);

	fRupture = fHitChance * NewRupture;
	fShred = fHitChance * NewShred;

	iTotalDamage = RollForInt(fTotalDamage);
	// Armor mitigation is related to damage, we do not roll separately for it.
	ArmorMitigation = iTotalDamage > fTotalDamage ? FFloor(fTotalArmorMitigation) : FCeil(fTotalArmorMitigation);
	// Shred is related to armor mitigation, we also do not roll for that.
	NewShred = Min(NewShred, ArmorMitigation);
	NewRupture = RollForInt(fRupture);

	`Log("");
	`Log("Damage:" @ RoundFloat(fTotalDamage) @ "=>" @ iTotalDamage);
	`Log("Rupture:" @ RoundFloat(fRupture) @ "(" $ RoundFloat(fHitChance) @ "*" @ NewRupture $ ")" @ "=>" @ NewRupture, fRupture != 0);
	`Log("Shred:" @ RoundFloat(fShred) @ "(" $ RoundFloat(fHitChance) @ "*" @ NewShred $ ")" @ "=>" @ NewShred, fShred != 0);

	`Log("");
	`Log("</ReliableDamage.Damage>");
	`Log("");

	return iTotalDamage;
}

simulated function GetDamagePreview(StateObjectReference TargetRef, XComGameState_Ability AbilityState, bool bAsPrimaryTarget, out WeaponDamageValue MinDamagePreview, out WeaponDamageValue MaxDamagePreview, out int AllowsShield)
{
	local float fHitChance, fMissChance, fCritChance, fGrazeChance, fMinDamage, fMaxDamage, fMinArmorMitigation, fMaxArmorMitigation;
	local int iMinDamage, iMaxDamage, iDamageOnCrit, iDamageOnMiss, iRuptureDamage, iShield, iArmor, iArmorPiercing, iMinArmorMitigation, iMaxArmorMitigation;
	local array<float> PlusOneDamage;
	local ApplyDamageInfo DamageInfo;
	local AbilityGameStateContext AbilityContext;

	// Default behavior
	super.GetDamagePreview(TargetRef, AbilityState, bAsPrimaryTarget, MinDamagePreview, MaxDamagePreview, AllowsShield);

	if(!Configuration.ApplyVsTheLost && UnitIsTheLost(TargetRef))
	{
		return;
	}

	AbilityContext = GetAbilityContext(AbilityState.GetReference(), TargetRef);
	DamageInfo = CalculateDamageInfo(AbilityContext);

	iShield = AbilityContext.TargetUnit != None ? AbilityContext.TargetUnit.GetCurrentStat(eStat_ShieldHP) : 0.0f;
	iArmorPiercing = GetArmorPiercing(AbilityContext, DamageInfo);
	iArmor = bIgnoreArmor ? 0 : GetArmorMitigation(TargetRef, iArmorPiercing);

	fHitChance = GetHitChance(AbilityState, TargetRef, fCritChance, fGrazeChance);
	fMissChance = 1.0f - fHitChance;
	iDamageOnMiss = GetDamageOnMiss(AbilityState);
	iDamageOnCrit = GetDamageOnCrit(AbilityContext, DamageInfo);
	PlusOneDamage = GetPlusOneDamage(DamageInfo);

	// XCOM adds Rupture bonus damage later as a constant bonus to both Minimum and Maximum damage.
	// We want to scale this bonus like all other damage so we add it here to both iMin & iMax damage
	// to scale it and at the end remove the fixed Rupture value to end up at the correct amount in the UI.
	iRuptureDamage = AbilityContext.TargetUnit != None ? AbilityContext.TargetUnit.GetRupturedValue() : 0;

	// We also include the preview Rupture as this is immediately applied to the target as damage as well.
	// This is something that XCOM leaves out by default as well and is incorrect so we fix that here.
	iMinDamage = MinDamagePreview.Damage + iRuptureDamage + MinDamagePreview.Rupture;
	iMaxDamage = MaxDamagePreview.Damage + iRuptureDamage + MaxDamagePreview.Rupture;

	if(Configuration.AdjustPlusOne) iMaxDamage = Max(0, iMaxDamage - PlusOneDamage.Length);

	CalculateExpectedDamageAndArmorMitigation(fHitChance, fMissChance, fCritChance, fGrazeChance, iMinDamage, iDamageOnMiss, iDamageOnCrit, PlusOneDamage, iShield, iArmor, fMinDamage, fMinArmorMitigation);
	CalculateExpectedDamageAndArmorMitigation(fHitChance, fMissChance, fCritChance, fGrazeChance, iMaxDamage, iDamageOnMiss, iDamageOnCrit, PlusOneDamage, iShield, iArmor, fMaxDamage, fMaxArmorMitigation);

	iMinArmorMitigation = fMinDamage == 0 ? FFloor(fMinArmorMitigation) : fMinDamage > iShield ? iArmor : FCeil(fMinArmorMitigation);
	iMaxArmorMitigation = fMaxDamage == 0 ? FCeil(fMaxArmorMitigation) : fMaxDamage > iShield ? iArmor : FFloor(fMaxArmorMitigation);

	// Damage
	MinDamagePreview.Damage = FFloor(fMinDamage) + iMinArmorMitigation - iRuptureDamage;
	MaxDamagePreview.Damage = FCeil(fMaxDamage) + iMaxArmorMitigation - iRuptureDamage;

	// Rupture
	MinDamagePreview.Rupture = FFloor(fHitChance * MinDamagePreview.Rupture);
	MaxDamagePreview.Rupture = FCeil(fHitChance * MaxDamagePreview.Rupture);

	// Shred
	MinDamagePreview.Shred = FFloor(fHitChance * MinDamagePreview.Shred);
	MaxDamagePreview.Shred = FCeil(fHitChance * MaxDamagePreview.Shred);
}

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local array<Name> ReserveActionPoints;
	local XComGameState_Unit TargetUnit;
	local int TotalDamage, HitChance, CurrentHealth;

	TargetUnit = XComGameState_Unit(kNewTargetState);
	if(TargetUnit != None)
	{
		CurrentHealth = TargetUnit.GetCurrentStat(eStat_HP) + TargetUnit.GetCurrentStat(eStat_ShieldHP);
		ReserveActionPoints = TargetUnit.ReserveActionPoints;
	}

	// Default behavior
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);

	if(ReserveActionPoints.Length == 0 || ApplyEffectParameters.AbilityResultContext.HitResult != eHit_Success)
	{
		return;
	}

	// We may have to restore Overwatch like abilities, as a Hit will have removed those.
	HitChance = ApplyEffectParameters.AbilityResultContext.CalculatedHitChance;
	TargetUnit = XComGameState_Unit(kNewTargetState);
	if(TargetUnit == None) return;

	TotalDamage = CurrentHealth - (TargetUnit.GetCurrentStat(eStat_HP) + TargetUnit.GetCurrentStat(eStat_ShieldHP));
	if(HitChance < Configuration.OverwatchRemovalMinimumHitChance || TotalDamage < Configuration.OverwatchRemovalMinimumDamage)
	{
		// Restore Overwatch
		TargetUnit.ReserveActionPoints = ReserveActionPoints;
	}
}

private function CalculateExpectedDamageAndArmorMitigation(float fHitChance, float fMissChance, float fCritChance, float fGrazeChance, int iDamageOnHit, int iDamageOnMiss, int iDamageOnCrit, array<float> PlusOneDamage, int iShield, int iArmor, out float fDamage, out float fArmorMitigation, optional bool bWriteToLog = false)
{
	local array<float> ZeroPlusOne;
	ZeroPlusOne.Length = 0;

	if(Configuration.AdjustCriticalHits) fHitChance -= fCritChance;
	if(Configuration.AdjustGrazeHits) fHitChance -= fGrazeChance;

	if(fHitChance > 0) ComputeExpectedValues(CalculateDamage("Hit", fHitChance, iDamageOnHit, PlusOneDamage, iShield, iArmor, bWriteToLog), fDamage, fArmorMitigation);
	if(fMissChance > 0 && iDamageOnMiss > 0) ComputeExpectedValues(CalculateDamage("Miss", fMissChance, iDamageOnMiss, ZeroPlusOne, iShield, iArmor, bWriteToLog), fDamage, fArmorMitigation);
	if(Configuration.AdjustCriticalHits && fCritChance > 0) ComputeExpectedValues(CalculateDamage("Crit", fCritChance, iDamageOnHit + iDamageOnCrit, PlusOneDamage, iShield, iArmor, bWriteToLog), fDamage, fArmorMitigation);
	if(Configuration.AdjustGrazeHits && fGrazeChance > 0) ComputeExpectedValues(CalculateDamage("Graze", fGrazeChance, iDamageOnHit * GRAZE_DMG_MULT, PlusOneDamage, iShield, iArmor, bWriteToLog), fDamage, fArmorMitigation);
}

private function ComputeExpectedValues(array<WeaponDamage> DamageEffects, out float fDamage, out float fArmorMitigation)
{
	local WeaponDamage DamageValue;

	foreach DamageEffects(DamageValue)
	{
		fDamage += DamageValue.Damage * DamageValue.HitChance;
		fArmorMitigation += DamageValue.ArmorMitigation * DamageValue.HitChance;
	}
}

private function array<WeaponDamage> CalculateDamage(string HitResult, float fHitChance, int iDamage, array<float> PlusOneDamage, int iShield, int iArmor, optional bool bWriteToLog = false)
{
	local array<WeaponDamage> DamageEffects;
	local int i, j, iPlusOneDamage;
	local float fDamageChance, fPlusOneChance;
	local bool bIsOn;
	local WeaponDamage Damage;

	if(!Configuration.AdjustPlusOne || PlusOneDamage.Length == 0)
	{
		DamageEffects.AddItem(GetDamageEffect(iDamage, iShield, iArmor, fHitChance));
	}
	else
	{
		// Each PlusOne chance acts as a bit (on or off, 1 or 0)
		// and thus we have a total of 2^PlusOneDamage.Length damage values.
		// One damage value for every combination of bit values.
		for(i = 0; i < 2 ** PlusOneDamage.Length; i++)
		{
			// The overall chance for this damage value
		    fDamageChance = fHitChance;
		    iPlusOneDamage = 0;

		    for(j = 0; j < PlusOneDamage.Length; j++)
		    {
		        fPlusOneChance = PlusOneDamage[j];
				// PlusOne damage is used when its bit is on (= 1)
				// in the current combination's integer value (0 - 2^[number of +1 values]-1)
		        bIsOn = (i & (1 << j)) > 0;

		        fDamageChance *= bIsOn ? fPlusOneChance : (1.0f - fPlusOneChance);
		        iPlusOneDamage += bIsOn ? 1 : 0;
		    }

			Damage = GetDamageEffect(iDamage + iPlusOneDamage, iShield, iArmor, fDamageChance);
			DamageEffects.AddItem(Damage);
		}
	}

	if(bWriteToLog)
	{
		`Log("");
		`Log("===" @ Round(fHitChance * 100) $ "%" @ "|" @ HitResult @ "|" @ iDamage @ "dmg" @ "===");

		foreach DamageEffects(Damage)
		{
			`Log("+" $ RoundFloat(Damage.Damage * Damage.HitChance) @ "(" $ RoundFloat(Damage.HitChance) @ "*" @ Damage.Damage $ ")");
		}
	}

	return DamageEffects;
}

private function WeaponDamage GetDamageEffect(int iDamage, int iShield, int iArmor, float fHitChance)
{
	local int iTotalDamage, iArmorMitigation;
	local WeaponDamage DamageEffect;

	iArmorMitigation = Clamp(iDamage - iShield, 0, iArmor);
	iTotalDamage = Max(0, iDamage - iArmorMitigation);

	DamageEffect.Damage = iTotalDamage;
	DamageEffect.ArmorMitigation = iArmorMitigation;
	DamageEffect.HitChance = fHitChance;

	return DamageEffect;
}

simulated function bool PlusOneDamage(int Chance)
{
	if(Configuration.AdjustPlusOne)
	{
		// We add the expected value of PlusOne to every shot,
		// the PlusOne effect should not occur here anymore.
		return false;
	}
	else
	{
		// Default behavior
		return super.PlusOneDamage(Chance);
	}
}

function static bool UnitIsTheLost(StateObjectReference TargetRef)
{
	local XComGameState_Unit TargetUnit;

	if(TargetRef.ObjectID <= 0) return false;

	TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(TargetRef.ObjectID));
	return TargetUnit != None && TargetUnit.GetTeam() == eTeam_TheLost;
}

private function ApplyDamageInfo CalculateDamageInfo(AbilityGameStateContext AbilityContext)
{
	local ApplyDamageInfo DamageInfo;
	local array<Name> AppliedDamageTypes;

	super.CalculateDamageValues(AbilityContext.SourceWeapon, AbilityContext.SourceUnit, AbilityContext.TargetUnit, AbilityContext.Ability, DamageInfo, AppliedDamageTypes);

	return DamageInfo;
}

private function float GetHitChance(XComGameState_Ability Ability, StateObjectReference TargetRef, optional out float fCritChance, optional out float fGrazeChance)
{
	local ShotBreakdown Breakdown;
	local int iHitChance, iCritChance;
	local float fHitChance;
	local X2AbilityToHitCalc_StandardAim_RD StandardAim;

	Ability.LookupShotBreakdown(Ability.OwnerStateObject, TargetRef, Ability.GetReference(), Breakdown);

	iHitChance = Clamp(Breakdown.bIsMultishot ? Breakdown.MultiShotHitChance : Breakdown.FinalHitChance, 0, 100);
	fHitChance = iHitChance / 100.0f;

	StandardAim = X2AbilityToHitCalc_StandardAim_RD(Ability.GetMyTemplate().AbilityToHitCalc);

	iCritChance = (StandardAim != None && StandardAim.bHitsAreCrits)
		// Special case when hits are always Critical hits, e.g. Grenadier's Rupture
		? Breakdown.ResultTable[eHit_Crit] + Breakdown.ResultTable[eHit_Success]
		: Breakdown.ResultTable[eHit_Crit];

	// Clamp Crit and Graze to a maximum of iHitChance to prevent
	// situations where the final hit chance is only 2% but game still claims
	// Crit chance is 10%.
	fCritChance = Clamp(iCritChance, 0, iHitChance) / 100.0f;
	fGrazeChance = Clamp(Breakdown.ResultTable[eHit_Graze], 0, iHitChance) / 100.0f;

	ModifyHitChanceForSpecialCase(Ability, TargetRef, fHitChance, fCritChance, fGrazeChance);

	return fHitChance;
}

private function float ModifyHitChanceForSpecialCase(XComGameState_Ability Ability, StateObjectReference TargetRef, out float fHitChance, out float fCritChance, out float fGrazeChance)
{
	MaybeModifyForChainShot(Ability, fHitChance, fCritChance, fGrazeChance);

	return fHitChance;
}

private function MaybeModifyForChainShot(XComGameState_Ability Ability, out float fHitChance, out float fCritChance, out float fGrazeChance)
{
	local float fMissChance, fMultiplier;

	if(Ability.GetMyTemplateName() == 'ChainShot' || Ability.GetMyTemplateName() == 'ChainShot2')
	{
		// In this mod, Chain Shot will always fire twice which makes it slightly stronger than intended.
		// We have to fix the dealt damage by lowering the Hit Chance with a multiplier of exactly 1.0 - (fMissChance / 2).
		// All hit chance components are scaled by this multiplier.
		fMissChance = 1.0 - fHitChance;
		fMultiplier = (1.0 - fMissChance / 2.0);

		fHitChance *= fMultiplier;
		fCritChance *= fMultiplier;
		fGrazeChance *= fMultiplier;
	}
}

private function int GetDamageOnMiss(XComGameState_Ability Ability)
{
	local XComGameState_Item Weapon;
	local array<X2WeaponUpgradeTemplate> WeaponUpgradeTemplates;
	local X2WeaponUpgradeTemplate WeaponUpgradeTemplate;
	local int iDamageOnHitOnMiss;

	Weapon = GetWeapon(Ability);
	if(Weapon == None) return 0;

	WeaponUpgradeTemplates = Weapon.GetMyWeaponUpgradeTemplates();
	foreach WeaponUpgradeTemplates(WeaponUpgradeTemplate)
	{
		if(WeaponUpgradeTemplate.BonusDamage.Tag == 'Miss')
		{
			iDamageOnHitOnMiss += WeaponUpgradeTemplate.BonusDamage.Damage;
		}
	}

	return iDamageOnHitOnMiss;
}

private function int GetDamageOnCrit(AbilityGameStateContext AbilityContext, ApplyDamageInfo DamageInfo)
{
	local XComGameState_Effect Effect;
	local StateObjectReference EffectRef;
	local X2Effect_Persistent EffectTemplate;
	local int iCritDamage;
	local EffectAppliedData TestEffectData;

	iCritDamage =
		DamageInfo.BaseDamageValue.Crit +
		DamageInfo.ExtraDamageValue.Crit +
		DamageInfo.BonusEffectDamageValue.Crit +
		DamageInfo.AmmoDamageValue.Crit +
		DamageInfo.UpgradeDamageValue.Crit;

	ChangeHitResults(TestEffectData.AbilityResultContext, eHit_Success, eHit_Crit);

	TestEffectData = CreateTestEffectData(AbilityContext.Ability, AbilityContext.TargetObject.GetReference());
	foreach AbilityContext.SourceUnit.AffectedByEffects(EffectRef)
	{
		Effect = XComGameState_Effect(GetGameStateObject(EffectRef));
		EffectTemplate = Effect.GetX2Effect();
		iCritDamage += EffectTemplate.GetAttackingDamageModifier(Effect, AbilityContext.SourceUnit, Damageable(AbilityContext.TargetObject), AbilityContext.Ability, TestEffectData, 0);
	}

	return iCritDamage;
}

private function int GetArmorPiercing(AbilityGameStateContext AbilityContext, ApplyDamageInfo DamageInfo)
{
	local XComGameState_Effect Effect;
	local StateObjectReference EffectRef;
	local X2Effect_Persistent EffectTemplate;
	local int iArmorPiercing;
	local EffectAppliedData TestEffectData;
	local int iExtraArmorPiercing;

	iArmorPiercing =
		DamageInfo.BaseDamageValue.Pierce +
		DamageInfo.ExtraDamageValue.Pierce +
		DamageInfo.BonusEffectDamageValue.Pierce +
		DamageInfo.AmmoDamageValue.Pierce +
		DamageInfo.UpgradeDamageValue.Pierce;

	TestEffectData = CreateTestEffectData(AbilityContext.Ability, AbilityContext.TargetObject.GetReference());
	foreach AbilityContext.SourceUnit.AffectedByEffects(EffectRef)
	{
		Effect = XComGameState_Effect(GetGameStateObject(EffectRef));
		EffectTemplate = Effect.GetX2Effect();
		iExtraArmorPiercing = EffectTemplate.GetExtraArmorPiercing(Effect, AbilityContext.SourceUnit, Damageable(AbilityContext.TargetObject), AbilityContext.Ability, TestEffectData);
		LogInt("Extra armor piercing from" @ EffectTemplate.Name, iExtraArmorPiercing, iExtraArmorPiercing > 0);
		iArmorPiercing += iExtraArmorPiercing;
	}

	return iArmorPiercing;
}

private function int GetArmorMitigation(StateObjectReference TargetRef, optional int Pierce = 0)
{
	local Damageable Damageable;
	local ArmorMitigationResults ArmorMitigationResults;
	local int iArmorMitigation;

	Damageable = Damageable(GetGameStateObject(TargetRef));
	if(Damageable == None) return 0;

	// Cannot be negative
	iArmorMitigation = Max(0, Damageable.GetArmorMitigation(ArmorMitigationResults));

	// Reduced by Pierce
	iArmorMitigation = Max(0, iArmorMitigation - Pierce);

	return iArmorMitigation;
}

private function EffectAppliedData CreateTestEffectData(XComGameState_Ability Ability, StateObjectReference TargetRef, optional XComGameState NewGameState)
{
	local EffectAppliedData TestEffectData;
	local XComGameState_Unit SourceUnit;

	SourceUnit = GetUnit(Ability.OwnerStateObject, NewGameState);
	TestEffectData.AbilityInputContext.AbilityRef = Ability.GetReference();
	TestEffectData.AbilityInputContext.AbilityTemplateName = Ability.GetMyTemplateName();
	TestEffectData.ItemStateObjectRef = Ability.SourceWeapon;
	TestEffectData.AbilityStateObjectRef = Ability.GetReference();
	TestEffectData.SourceStateObjectRef = SourceUnit.GetReference();
	TestEffectData.PlayerStateObjectRef = SourceUnit.ControllingPlayer;
	TestEffectData.TargetStateObjectRef = TargetRef;
	TestEffectData.AbilityInputContext.PrimaryTarget = TargetRef;

	return TestEffectData;
}

private function array<float> GetPlusOneDamage(ApplyDamageInfo DamageInfo)
{
	local array<float> PlusOneDamage;

	if(DamageInfo.BaseDamageValue.PlusOne > 0) PlusOneDamage.AddItem(Min(100, DamageInfo.BaseDamageValue.PlusOne) / 100.0f);
	if(DamageInfo.ExtraDamageValue.PlusOne > 0) PlusOneDamage.AddItem(Min(100, DamageInfo.ExtraDamageValue.PlusOne) / 100.0f);
	if(DamageInfo.BonusEffectDamageValue.PlusOne > 0) PlusOneDamage.AddItem(Min(100, DamageInfo.BonusEffectDamageValue.PlusOne) / 100.0f);
	if(DamageInfo.AmmoDamageValue.PlusOne > 0) PlusOneDamage.AddItem(Min(100, DamageInfo.AmmoDamageValue.PlusOne) / 100.0f);
	if(DamageInfo.UpgradeDamageValue.PlusOne > 0) PlusOneDamage.AddItem(Min(100, DamageInfo.UpgradeDamageValue.PlusOne) / 100.0f);

	return PlusOneDamage;
}

private function AbilityGameStateContext GetAbilityContext(StateObjectReference AbilityRef, StateObjectReference TargetRef, optional XComGameState NewGameState)
{
	local AbilityGameStateContext Context;
	local XComGameState_Ability Ability;

	Ability = GetAbility(AbilityRef);

	Context.Ability = Ability;
	Context.SourceUnit = GetUnit(Ability.OwnerStateObject, NewGameState);
	Context.SourceWeapon = GetWeapon(Ability);
	Context.TargetObject = GetGameStateObject(TargetRef, NewGameState);
	Context.TargetUnit = XComGameState_Unit(Context.TargetObject);

	return Context;
}

private function XComGameState_Item GetWeapon(XComGameState_Ability Ability)
{
	return Ability.SourceAmmo.ObjectID > 0
		? Ability.GetSourceAmmo()
		: Ability.GetSourceWeapon();
}

private function XComGameState_Unit GetUnit(StateObjectReference UnitRef, optional XComGameState NewGameState)
{
	return XComGameState_Unit(GetGameStateObject(UnitRef, NewGameState));
}

private function XComGameState_Ability GetAbility(StateObjectReference AbilityRef, optional XComGameState NewGameState)
{
	return XComGameState_Ability(GetGameStateObject(AbilityRef, NewGameState));
}

private function XComGameState_BaseObject GetGameStateObject(StateObjectReference ObjectRef, optional XComGameState NewGameState)
{
	local XComGameState_BaseObject GameStateObject;

	// First try to read from NewGameState and otherwise fall back to History.
	if(NewGameState != None) GameStateObject = NewGameState.GetGameStateForObjectID(ObjectRef.ObjectID);
	return GameStateObject != None ? GameStateObject : `XCOMHISTORY.GetGameStateForObjectID(ObjectRef.ObjectID);
}

private function ChangeHitResults(out AbilityResultContext ResultContext, EAbilityHitResult ChangeFrom, EAbilityHitResult ChangeTo)
{
	local int i;

	if(ResultContext.HitResult == ChangeFrom)
	{
		ResultContext.HitResult = ChangeTo;
	}

	for(i = 0; i < ResultContext.MultiTargetHitResults.Length; i++)
	{
		if(ResultContext.MultiTargetHitResults[i] == ChangeFrom)
		{
			ResultContext.MultiTargetHitResults[i] = ChangeTo;
		}
	}
}

private function int RollForInt(float Value)
{
	local int MinValue, MaxValue, MaxValueChance;

	MinValue = FFloor(Value);
	MaxValue = FCeil(Value);

	MaxValueChance = Round((Value - MinValue) * 100);
	return `SYNC_RAND(100) < MaxValueChance ? MaxValue : MinValue;
}

private function string RoundFloat(float Value)
{
	local string sValue;
	sValue = string(Round(Value * 100) / 100.0f);
	return Left(sValue, Len(sValue) - 2);
}

private function LogFloat(string Message, float Number, optional bool Condition = true)
{
	`Log(Message @ RoundFloat(Number), Condition);
}

private function LogInt(string Message, int Number, optional bool Condition = true)
{
	`Log(Message @ Number, Condition);
}

private function LogHitChance(string Message, float HitChance, optional bool Condition = true)
{
	`Log(Message @ Round(HitChance * 100) $ "%", Condition);
}

private function LogUnit(string Message, XComGameState_Unit Unit)
{
	local name SoldierClass;
	SoldierClass = Unit.GetSoldierClassTemplateName();
	`Log(Message @ "[" $ (SoldierClass != '' ? SoldierClass : Unit.GetMyTemplateName()) $ "]" @ Unit.GetName(eNameType_FullNick));
}

private function LogItem(string Message, XComGameState_Item Item)
{
	local X2ItemTemplate ItemTemplate;
	ItemTemplate = Item.GetMyTemplate();

	`Log(Message @ "[" $ Item.GetMyTemplateName() $ "]" $ (ItemTemplate.HasDisplayData() ? "" @ ItemTemplate.GetItemFriendlyName() : ""));
}

private function LogAbility(string Message, XComGameState_Ability Ability)
{
	`Log(Message @ "[" $ Ability.GetMyTemplateName() $ "]" @ Ability.GetMyFriendlyName());
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, name EffectApplyResult)
{
	local XComGameStateVisualizationMgr VisualizationMgr;
	local array<X2Action> Actions;
	local X2Action Action;
	local X2Action_ApplyWeaponDamageToUnit ApplyWeaponDamageAction;

	VisualizationMgr = `XCOMVISUALIZATIONMGR;
	VisualizationMgr.GetNodesOfType(VisualizationMgr.BuildVisTree, class'X2Action_ApplyWeaponDamageToUnit', Actions);

	foreach Actions(Action)
	{
		ApplyWeaponDamageAction = X2Action_ApplyWeaponDamageToUnit(Action);
		if(ApplyWeaponDamageAction == None) continue;

		if(X2Effect_ApplyWeaponDamage_RD(ApplyWeaponDamageAction.OriginatingEffect) == None)
		{
			// Remove any instances of X2Action_ApplyWeaponDamageToUnit that were added by
			// an X2Effect that is not X2Effect_ApplyWeaponDamage_RD.
			// In practice this is to remove Actions added by the X2Effect_ApplyWeaponDamage
			// that we have replaced but could not remove from the list of TargetEffects.
			// This fix is necessary to prevent a RedScreen during Sharpshooter's Faceoff ability.
			VisualizationMgr.DisconnectAction(Action);
		}
	}

	// Default behavior
	super.AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);
}

defaultproperties
{
	Begin Object Class=Configuration Name=Configuration
	End Object
	Configuration=Configuration
}
