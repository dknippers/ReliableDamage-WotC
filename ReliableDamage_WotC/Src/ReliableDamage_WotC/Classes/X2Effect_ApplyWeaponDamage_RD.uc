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
	local int iTotalDamage, iDamageOnHit, iDamageOnMiss, iDamageOnCrit, iArmorPiercing, iRemainingArmor;
	local float fHitChance, fMissChance, fCritChance, fGrazeChance, fTotalDamage, fDamageOnHit, fDamageOnMiss, fDamageOnCrit, fDamageOnGraze, fDamageOnPlusOne, fShred, fRupture;
	local AbilityGameStateContext AbilityContext;
	local ApplyDamageInfo DamageInfo;

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

	AbilityContext = GetAbilityContext(ApplyEffectParameters.AbilityStateObjectRef, ApplyEffectParameters.TargetStateObjectRef, NewGameState);
	DamageInfo = CalculateDamageInfo(AbilityContext);

	iArmorPiercing = GetArmorPiercing(AbilityContext, DamageInfo);
	AdjustDamageAndRemainingArmor(ApplyEffectParameters.TargetStateObjectRef, ArmorMitigation, iArmorPiercing, iDamageOnHit, iRemainingArmor);

	`Log("");
	`Log("<ReliableDamage.Damage>");
	`Log("");

	LogUnit("Source:", AbilityContext.SourceUnit);
	LogAbility("Ability:", AbilityContext.Ability);
	if(AbilityContext.SourceWeapon != None) LogItem("Weapon:", AbilityContext.SourceWeapon);
	if(AbilityContext.TargetUnit != None) LogUnit("Target:", AbilityContext.TargetUnit);
	else if(AbilityContext.TargetObject != None) `Log("Target:" @ AbilityContext.TargetObject.Class);

	`Log("");
	LogInt("IN Damage", iDamageOnHit);
	LogInt("IN Rupture", NewRupture, NewRupture != 0);
	LogInt("IN Shred", NewShred, NewShred != 0);

	fHitChance = GetHitChance(AbilityContext.Ability, ApplyEffectParameters.TargetStateObjectRef, fCritChance, fGrazeChance);
	fMissChance = 1.0f - fHitChance;

	fDamageOnHit = fHitChance * iDamageOnHit;

	iDamageOnMiss = GetDamageOnMiss(AbilityContext.Ability);
	fDamageOnMiss = fMissChance * iDamageOnMiss;

	iDamageOnCrit = GetDamageOnCrit(AbilityContext, DamageInfo);
	fDamageOnCrit = Configuration.AdjustCriticalHits ? fCritChance * iDamageOnCrit : 0.0f;

	fDamageOnPlusOne = Configuration.AdjustPlusOne ? fHitChance * GetPlusOneExpectedValue(DamageInfo) : 0.0f;
	fDamageOnGraze = Configuration.AdjustGrazeHits ? fGrazeChance * iDamageOnHit * (1.0f - GRAZE_DMG_MULT) : 0.0f;

	fTotalDamage = FMax(0, fDamageOnHit + fDamageOnMiss + fDamageOnCrit + fDamageOnPlusOne - fDamageOnGraze - iRemainingArmor);

	fRupture = fHitChance * NewRupture;
	fShred = fHitChance * NewShred;

	iTotalDamage = RollForInt(fTotalDamage);
	NewRupture = RollForInt(fRupture);
	NewShred = RollForInt(fShred);

	`Log("--------------------");
	LogHitChance("HitChance", fHitChance);
	LogFloat("HitDamage", fDamageOnHit, fDamageOnMiss != 0 || fDamageOnCrit != 0 || fDamageOnGraze != 0 || fDamageOnPlusOne != 0 || iRemainingArmor != 0);
	LogFloat("MissDamage", fDamageOnMiss, fDamageOnMiss != 0);
	LogHitChance("CritChance", fCritChance, fDamageOnCrit != 0);
	LogFloat("CritDamage", fDamageOnCrit, fDamageOnCrit != 0);
	LogFloat("PlusOneDamage", fDamageOnPlusOne, fDamageOnPlusOne != 0);
	LogHitChance("GrazeChance", fGrazeChance, fDamageOnGraze != 0);
	LogFloat("GrazeDamage", -1 * fDamageOnGraze, fDamageOnGraze != 0);
	LogInt("RemainingArmor", -1 * iRemainingArmor, iRemainingArmor != 0);
	`Log("--");
	LogFloat("TotalDamage", fTotalDamage);
	LogFloat("TotalRupture", fRupture, fRupture != 0);
	LogFloat("TotalShred", fShred, fShred != 0);
	`Log("--------------------");

	LogInt("OUT Damage", iTotalDamage);
	LogInt("OUT Rupture", NewRupture, fRupture != 0);
	LogInt("OUT Shred", NewShred, fShred != 0);

	`Log("");
	`Log("</ReliableDamage.Damage>");
	`Log("");

	return iTotalDamage;
}

simulated function GetDamagePreview(StateObjectReference TargetRef, XComGameState_Ability AbilityState, bool bAsPrimaryTarget, out WeaponDamageValue MinDamagePreview, out WeaponDamageValue MaxDamagePreview, out int AllowsShield)
{
	local float fHitChance, fMissChance, fCritChance, fGrazeChance, fMinDamage, fMaxDamage, fDamageOnMiss, fDamageOnCrit, fMinDamageOnGraze, fMaxDamageOnGraze, fDamageOnPlusOne;
	local int iMinDamage, iMaxDamage, iMaxPlusOneDamage, iRuptureDamage;
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

	fHitChance = GetHitChance(AbilityState, TargetRef, fCritChance, fGrazeChance);
	fMissChance = 1.0f - fHitChance;
	fDamageOnMiss = fMissChance * GetDamageOnMiss(AbilityState);
	fDamageOnCrit = Configuration.AdjustCriticalHits ? fCritChance * GetDamageOnCrit(AbilityContext, DamageInfo) : 0.0f;
	fDamageOnPlusOne = Configuration.AdjustPlusOne ? fHitChance * GetPlusOneExpectedValue(DamageInfo, iMaxPlusOneDamage) : 0.0f;

	// XCOM adds Rupture bonus damage later as a constant bonus to both Minimum and Maximum damage.
	// We want to scale this bonus like all other damage so we add it here to both iMin & iMax damage
	// to scale it and at the end remove the fixed Rupture value to end up at the correct amount in the UI.
	iRuptureDamage = AbilityContext.TargetUnit != None ? AbilityContext.TargetUnit.GetRupturedValue() : 0;

	// We also include the preview Rupture as this is immediately applied to the target as damage as well.
	// This is something that XCOM leaves out by default as well and is incorrect so we fix that here.
	iMinDamage = Max(0, MinDamagePreview.Damage + iRuptureDamage + MinDamagePreview.Rupture);
	iMaxDamage = Max(0, MaxDamagePreview.Damage + iRuptureDamage + MaxDamagePreview.Rupture - iMaxPlusOneDamage);

	fMinDamage = fHitChance * iMinDamage;
	fMaxDamage = fHitChance * iMaxDamage;

	fMinDamageOnGraze = Configuration.AdjustGrazeHits ? fGrazeChance * iMinDamage * (1.0f - GRAZE_DMG_MULT) : 0.0f;
	fMaxDamageOnGraze = Configuration.AdjustGrazeHits ? fGrazeChance * iMaxDamage * (1.0f - GRAZE_DMG_MULT) : 0.0f;

	// Damage
	MinDamagePreview.Damage = FFloor(fMinDamage + fDamageOnMiss + fDamageOnCrit + fDamageOnPlusOne - fMinDamageOnGraze) - iRuptureDamage;
	MaxDamagePreview.Damage = FCeil(fMaxDamage + fDamageOnMiss + fDamageOnCrit + fDamageOnPlusOne - fMaxDamageOnGraze) - iRuptureDamage;

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

// If a unit should deal 0 damage because the target unit's armor > the source unit damage
// XCOM changes the armor mitigation to [damage - 1], i.e. the source unit will always deal
// at least 1 damage even though the target's armor could have blocked all damage.
// Because our mod lowers most output damage the situation where armor > damage will happen
// more often and we do not want to abuse this free 1 damage mechanic.
// We fix that behavior by adjusting the damage value and remaining armor accordingly.
private function AdjustDamageAndRemainingArmor(StateObjectReference TargetRef, int iArmorMitigation, int iArmorPiercing, out int iDamage, out int iRemainingArmor)
{
	local int iTotalArmor;

	iTotalArmor = bIgnoreArmor ? 0 : GetArmorMitigation(TargetRef, iArmorPiercing);
	iRemainingArmor = Max(0, iTotalArmor - iArmorMitigation);
	if(iRemainingArmor == 0) return;

	if(iRemainingArmor >= iDamage)
	{
		iRemainingArmor -= iDamage;
		iDamage = 0;
	}
	else
	{
		iDamage -= iRemainingArmor;
		iRemainingArmor = 0;
	}
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
	local int iHitChance;
	local float fHitChance;
	local X2AbilityToHitCalc_StandardAim_RD StandardAim;

	Ability.LookupShotBreakdown(Ability.OwnerStateObject, TargetRef, Ability.GetReference(), Breakdown);

	iHitChance = Clamp(Breakdown.bIsMultishot ? Breakdown.MultiShotHitChance : Breakdown.FinalHitChance, 0, 100);
	fHitChance = iHitChance / 100.0f;

	StandardAim = X2AbilityToHitCalc_StandardAim_RD(Ability.GetMyTemplate().AbilityToHitCalc);
	fCritChance = (StandardAim != None && StandardAim.bHitsAreCrits)
		? fHitChance // Special case when hits are always Critical hits, e.g. Grenadier's Rupture
		: Clamp(Breakdown.ResultTable[eHit_Crit], 0, 100) / 100.0f;

	fGrazeChance = Clamp(Breakdown.ResultTable[eHit_Graze], 0, 100) / 100.0f;

	ModifyHitChanceForSpecialCase(Ability, TargetRef, fHitChance);

	return fHitChance;
}

private function float ModifyHitChanceForSpecialCase(XComGameState_Ability Ability, StateObjectReference TargetRef, out float fHitChance)
{
	MaybeModifyForChainShot(Ability, fHitChance);

	return fHitChance;
}

private function MaybeModifyForChainShot(XComGameState_Ability Ability, out float fHitChance)
{
	local float fMissChance;

	if(Ability.GetMyTemplateName() == 'ChainShot' || Ability.GetMyTemplateName() == 'ChainShot2')
	{
		// In this mod, Chain Shot will always fire twice which makes it slightly stronger than intended.
		// We have to fix the dealt damage by lowering the Hit Chance with a multiplier of exactly 1.0 - (fMissChance / 2).
		fMissChance = 1.0 - fHitChance;
		fHitChance *= (1.0 - fMissChance / 2.0);
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

private function float GetPlusOneExpectedValue(ApplyDamageInfo DamageInfo, optional out int MaxDamage)
{
	local int TotalPlusOne;

	if(DamageInfo.BaseDamageValue.PlusOne > 0)
	{
		MaxDamage++;
		TotalPlusOne += Min(100, DamageInfo.BaseDamageValue.PlusOne);
	}

	if(DamageInfo.ExtraDamageValue.PlusOne > 0)
	{
		MaxDamage++;
		TotalPlusOne += Min(100, DamageInfo.ExtraDamageValue.PlusOne);
	}

	if(DamageInfo.BonusEffectDamageValue.PlusOne > 0)
	{
		MaxDamage++;
		TotalPlusOne += Min(100, DamageInfo.BonusEffectDamageValue.PlusOne);
	}

	if(DamageInfo.AmmoDamageValue.PlusOne > 0)
	{
		MaxDamage++;
		TotalPlusOne += Min(100, DamageInfo.AmmoDamageValue.PlusOne);
	}

	if(DamageInfo.UpgradeDamageValue.PlusOne > 0)
	{
		MaxDamage++;
		TotalPlusOne += Min(100, DamageInfo.UpgradeDamageValue.PlusOne);
	}

	// The expected value is simply the total plus one probability
	// divided by 100, as each instance of PlusOne adds exactly 1 damage.
	return TotalPlusOne / 100.0f;
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

private function LogFloat(string Message, float Number, optional bool Condition = true)
{
	local string Rounded;
	Rounded = string(int(Number * 100) / 100.0f);
	`Log(Message @ Left(Rounded, Len(Rounded) - 2), Condition);
}

private function LogInt(string Message, int Number, optional bool Condition = true)
{
	`Log(Message @ Number, Condition);
}

private function LogHitChance(string Message, float HitChance, optional bool Condition = true)
{
	`Log(Message @ int(HitChance * 100) $ "%", Condition);
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
