class X2Effect_ApplyWeaponDamage_RD extends X2Effect_ApplyWeaponDamage;

var X2Effect_ApplyWeaponDamage Original;

struct AbilityGameStateContext
{
	var StateObjectReference AbilityRef;
	var StateObjectReference SourceRef;
	var StateObjectReference TargetRef;

	var XComGameState_Ability Ability;
	var XComGameState_Unit SourceUnit;
	var XComGameState_Item SourceWeapon;
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
	local int iTotalDamage, iDamageOnHit, iDamageOnMiss, iDamageOnCrit, iDamageOnGraze;
	local float fHitChance, fMissChance, fCritChance, fGrazeChance, fTotalDamage, fDamageOnHit, fDamageOnMiss, fDamageOnCrit, fDamageOnGraze, fShred, fRupture;
	local AbilityGameStateContext AbilityContext;

	// Calculate damage as usual
	iDamageOnHit = super.CalculateDamageAmount(ApplyEffectParameters, ArmorMitigation, NewRupture, NewShred, AppliedDamageTypes, bAmmoIgnoresShields, bFullyImmune, SpecialDamageMessages, NewGameState);

	if(ApplyEffectParameters.AbilityResultContext.HitResult != eHit_Success)
	{
		// We only adjust damage for regular hits. Do not touch anything else.
		return iDamageOnHit;
	}

	AbilityContext = GetAbilityContext(ApplyEffectParameters.AbilityStateObjectRef, ApplyEffectParameters.TargetStateObjectRef);

	`Log("");
	`Log("<ReliableDamage.Damage>");

	`Log("Source:" @ AbilityContext.SourceUnit.GetName(eNameType_FullNick));
	`Log("Ability:" @ AbilityContext.Ability.GetMyTemplateName());
	if(AbilityContext.TargetUnit != None) `Log("Target:" @ AbilityContext.TargetUnit.GetName(eNameType_FullNick));

	`Log("IN Damage" @ iDamageOnHit);
	`Log("IN Rupture" @ NewRupture, NewRupture > 0);
	`Log("IN Shred" @ NewShred, NewShred > 0);

	fHitChance = GetHitChance(AbilityContext.Ability, AbilityContext.TargetRef, fCritChance, fGrazeChance);
	fMissChance = 1.0f - fHitChance;

	fDamageOnHit = fHitChance * iDamageOnHit;

	iDamageOnMiss = GetDamageOnMiss(AbilityContext.Ability);
	fDamageOnMiss = fMissChance * iDamageOnMiss;

	iDamageOnCrit = GetDamageOnCrit(AbilityContext.Ability, AbilityContext.TargetRef);
	fDamageOnCrit = fCritChance * iDamageOnCrit;

	// Note this should be negative number; a Graze hit reduces damage taken
	iDamageOnGraze = (iDamageOnHit * GRAZE_DMG_MULT) - iDamageOnHit;
	fDamageOnGraze = fGrazeChance * iDamageOnGraze;

	fTotalDamage = fDamageOnHit + fDamageOnMiss + fDamageOnCrit + fDamageOnGraze;

	fRupture = fHitChance * NewRupture;
	fShred = fHitChance * NewShred;

	iTotalDamage = RollForInt(fTotalDamage);
	NewRupture = RollForInt(fRupture);
	NewShred = RollForInt(fShred);

	`Log("fHitChance" @ fHitChance);
	`Log("fDamageOnHit" @ fDamageOnHit, fDamageOnHit != 0);
	`Log("fDamageOnMiss" @ fDamageOnMiss, fDamageOnMiss != 0);
	`Log("fDamageOnCrit" @ fDamageOnCrit, fDamageOnCrit != 0);
	`Log("fDamageOnGraze" @ fDamageOnGraze, fDamageOnGraze != 0);
	`Log("fTotalDamage" @ fTotalDamage);
	`Log("fRupture" @ fRupture, NewRupture > 0);
	`Log("fShred" @ fShred, NewShred > 0);

	`Log("OUT Damage" @ iTotalDamage);
	`Log("OUT Rupture" @ NewRupture, fRupture > 0);
	`Log("OUT Shred" @ NewShred, fShred > 0);

	`Log("</ReliableDamage.Damage>");
	`Log("");

	return iTotalDamage;
}

simulated function GetDamagePreview(StateObjectReference TargetRef, XComGameState_Ability AbilityState, bool bAsPrimaryTarget, out WeaponDamageValue MinDamagePreview, out WeaponDamageValue MaxDamagePreview, out int AllowsShield)
{
	local float fHitChance, fMinDamage, fMaxDamage, fMissChance, fDamageOnMiss, fDamageOnCrit, fMinDamageOnGraze, fMaxDamageOnGraze, fCritChance, fGrazeChance;
	local int iArmorMitigation, iMinDamage, iMaxDamage, iMinDamageOnGraze, iMaxDamageOnGraze;

	// Default behavior
	super.GetDamagePreview(TargetRef, AbilityState, bAsPrimaryTarget, MinDamagePreview, MaxDamagePreview, AllowsShield);

	fHitChance = GetHitChance(AbilityState, TargetRef, fCritChance, fGrazeChance);
	fMissChance = 1.0f - fHitChance;
	fDamageOnMiss = fMissChance * GetDamageOnMiss(AbilityState);
	fDamageOnCrit = fCritChance * GetDamageOnCrit(AbilityState, TargetRef);

	iArmorMitigation = GetArmorMitigation(TargetRef, MaxDamagePreview.Damage, MaxDamagePreview.Pierce);

	iMinDamage = Max(0, MinDamagePreview.Damage - iArmorMitigation);
	iMaxDamage = Max(0, MaxDamagePreview.Damage - iArmorMitigation);

	fMinDamage = fHitChance * iMinDamage;
	fMaxDamage = fHitChance * iMaxDamage;

	iMinDamageOnGraze = (iMinDamage * GRAZE_DMG_MULT) - iMinDamage;
	iMaxDamageOnGraze = (iMaxDamage * GRAZE_DMG_MULT) - iMaxDamage;

	fMinDamageOnGraze = fGrazeChance * iMinDamageOnGraze;
	fMaxDamageOnGraze = fGrazeChance * iMaxDamageOnGraze;

	// Damage
	MinDamagePreview.Damage = iArmorMitigation + FFloor(fMinDamage + fDamageOnMiss + fDamageOnCrit + fMinDamageOnGraze);
	MaxDamagePreview.Damage = iArmorMitigation + FCeil(fMaxDamage + fDamageOnMiss + fDamageOnCrit + fMaxDamageOnGraze);

	// Rupture
	MinDamagePreview.Rupture = FFloor(fHitChance * MinDamagePreview.Rupture);
	MaxDamagePreview.Rupture = FCeil(fHitChance * MaxDamagePreview.Rupture);

	// Shred
	MinDamagePreview.Shred = FFloor(fHitChance * MinDamagePreview.Shred);
	MaxDamagePreview.Shred = FCeil(fHitChance * MaxDamagePreview.Shred);
}

private function float GetHitChance(XComGameState_Ability Ability, StateObjectReference TargetRef, optional out float fCritChance, optional out float fGrazeChance)
{
	local ShotBreakdown Breakdown;
	local int iHitChance;
	local float fHitChance;

	Ability.LookupShotBreakdown(Ability.OwnerStateObject, TargetRef, Ability.GetReference(), Breakdown);

	iHitChance = Clamp(Breakdown.bIsMultishot ? Breakdown.MultiShotHitChance : Breakdown.FinalHitChance, 0, 100);

	fHitChance = iHitChance / 100.0f;
	fCritChance = Clamp(Breakdown.ResultTable[eHit_Crit], 0, 100) / 100.0f;
	fGrazeChance = Clamp(Breakdown.ResultTable[eHit_Graze], 0, 100) / 100.0f;

	ModifyHitChanceForSpecialCase(Ability, TargetRef, fHitChance);

	return fHitChance;
}

private function float ModifyHitChanceForSpecialCase(XComGameState_Ability Ability, StateObjectReference TargetRef, out float fHitChance)
{
	// TODO: Handle cases like ChainShot here which need the HitChance lowered.
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

private function int GetDamageOnCrit(XComGameState_Ability Ability, StateObjectReference TargetRef)
{
	local ApplyDamageInfo DamageInfo;
	local XComGameState_Item SourceWeapon;
	local XComGameState_Unit SourceUnit, TargetUnit;
	local Damageable Damageable;
	local XComGameState_Effect Effect;
	local StateObjectReference EffectRef;
	local X2Effect_Persistent EffectTemplate;
	local int iCritDamage;
	local EffectAppliedData TestEffectData;
	local array<name> AppliedDamageTypes;

	AppliedDamageTypes.Length = 0;
	TestEffectData = CreateTestEffectData(Ability, TargetRef);
	SourceWeapon = GetWeapon(Ability);
	SourceUnit = GetUnit(Ability.OwnerStateObject);
	TargetUnit = GetUnit(TargetRef);
	Damageable = Damageable(TargetUnit);

	super.CalculateDamageValues(SourceWeapon, SourceUnit, TargetUnit, Ability, DamageInfo, AppliedDamageTypes);

	iCritDamage = SumCrit(DamageInfo);

	ChangeHitResults(TestEffectData.AbilityResultContext, eHit_Success, eHit_Crit);

	foreach SourceUnit.AffectedByEffects(EffectRef)
	{
		Effect = XComGameState_Effect(GetGameStateObject(EffectRef));
		EffectTemplate = Effect.GetX2Effect();
		iCritDamage += EffectTemplate.GetAttackingDamageModifier(Effect, SourceUnit, Damageable, Ability, TestEffectData, 0);
	}

	return iCritDamage;
}

private function EffectAppliedData CreateTestEffectData(XComGameState_Ability Ability, StateObjectReference TargetRef)
{
	local EffectAppliedData TestEffectData;
	local XComGameState_Unit SourceUnit;

	SourceUnit = GetUnit(Ability.OwnerStateObject);
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

private function int SumCrit(ApplyDamageInfo DamageInfo)
{
	return
		DamageInfo.BaseDamageValue.Crit +
		DamageInfo.ExtraDamageValue.Crit +
		DamageInfo.BonusEffectDamageValue.Crit +
		DamageInfo.AmmoDamageValue.Crit +
		DamageInfo.UpgradeDamageValue.Crit;
}

private function AbilityGameStateContext GetAbilityContext(StateObjectReference AbilityRef, StateObjectReference TargetRef)
{
	local AbilityGameStateContext Context;
	local XComGameState_Ability Ability;

	Ability = GetAbility(AbilityRef);

	Context.AbilityRef = AbilityRef;
	Context.SourceRef = Ability.OwnerStateObject;
	Context.TargetRef = TargetRef;

	Context.Ability = Ability;
	Context.SourceUnit = GetUnit(Ability.OwnerStateObject);
	Context.SourceWeapon = GetWeapon(Ability);
	Context.TargetUnit = GetUnit(TargetRef);

	return Context;
}

private function XComGameState_Item GetWeapon(XComGameState_Ability Ability)
{
	return Ability.SourceAmmo.ObjectID > 0
		? Ability.GetSourceAmmo()
		: Ability.GetSourceWeapon();
}

private function XComGameState_Unit GetUnit(StateObjectReference UnitRef)
{
	return XComGameState_Unit(GetGameStateObject(UnitRef));
}

private function XComGameState_Ability GetAbility(StateObjectReference AbilityRef)
{
	return XComGameState_Ability(GetGameStateObject(AbilityRef));
}

private function XComGameState_BaseObject GetGameStateObject(StateObjectReference ObjectRef)
{
	return `XCOMHISTORY.GetGameStateForObjectID(ObjectRef.ObjectID);
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

private function int GetArmorMitigation(StateObjectReference TargetRef, optional int Damage = 0, optional int Pierce = 0)
{
	local Damageable Damageable;
	local ArmorMitigationResults ArmorMitigationResults;
	local int iArmorMitigation;

	Damageable = Damageable(GetGameStateObject(TargetRef));
	if(Damageable == None) return 0;

	// Cannot be negative
	iArmorMitigation = Max(0, Damageable.GetArmorMitigation(ArmorMitigationResults));

	// Cannot exceed damage
	iArmorMitigation = Min(Damage, iArmorMitigation);

	// Reduced by Pierce
	iArmorMitigation = Max(0, iArmorMitigation - Pierce);

	return iArmorMitigation;
}
