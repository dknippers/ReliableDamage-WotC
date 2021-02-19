class X2Effect_ApplyWeaponDamage_RD extends X2Effect_ApplyWeaponDamage;

var X2Effect_ApplyWeaponDamage Original;

var X2Condition_Toggle_RD OriginalToggleCondition;

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
	local int iDamage;
	local float fHitChance, fDamage, fShred, fRupture;

	// Calculate damage as usual
	iDamage = super.CalculateDamageAmount(ApplyEffectParameters, ArmorMitigation, NewRupture, NewShred, AppliedDamageTypes, bAmmoIgnoresShields, bFullyImmune, SpecialDamageMessages, NewGameState);

	`Log("");
	`Log("<ReliableDamage.Damage>");

	`Log("IN Damage =" @ iDamage);
	`Log("IN ArmorMitigation =" @ ArmorMitigation, ArmorMitigation > 0);
	`Log("IN NewRupture =" @ NewRupture, NewRupture > 0);
	`Log("IN NewShred =" @ NewShred, NewShred > 0);

	// Update calculated damage based on hit chance
	fHitChance = GetHitChance(GetAbility(ApplyEffectParameters.AbilityStateObjectRef), ApplyEffectParameters.TargetStateObjectRef);

	fDamage = fHitChance * iDamage;
	fRupture = fHitChance * NewRupture;
	fShred = fHitChance * NewShred;

	iDamage = RollForInt(fDamage);
	NewRupture = RollForInt(fRupture);
	NewShred = RollForInt(fShred);

	`Log("fHitChance =" @ fHitChance);
	`Log("fDamage =" @ fDamage);

	`Log("OUT Damage =" @ iDamage);
	`Log("OUT Rupture =" @ NewRupture, fRupture > 0);
	`Log("OUT Shred =" @ NewShred, fShred > 0);

	`Log("</ReliableDamage.Damage>");
	`Log("");

	return iDamage;
}

private function float GetHitChance(XComGameState_Ability Ability, StateObjectReference TargetRef)
{
	local ShotBreakdown Breakdown;
	local int iHitChance;
	local float fHitChance;

	Ability.LookupShotBreakdown(Ability.OwnerStateObject, TargetRef, Ability.GetReference(), Breakdown);

	iHitChance = Clamp(Breakdown.bIsMultishot ? Breakdown.MultiShotHitChance : Breakdown.FinalHitChance, 0, 100);

	// Return HitChance as a value between 0.0 and 1.0
	fHitChance = iHitChance / 100.0f;

	ModifyHitChanceForSpecialCase(Ability, TargetRef, fHitChance);

	return fHitChance;
}

private function float ModifyHitChanceForSpecialCase(XComGameState_Ability Ability, StateObjectReference TargetRef, out float fHitChance)
{
	// TODO: Handle cases like ChainShot here which need the HitChance lowered.	
}

private function int RollForInt(float Value)
{
	local int MinValue, MaxValue, MaxValueChance;

	MinValue = FFloor(Value);
	MaxValue = FCeil(Value);

	MaxValueChance = Round((Value - MinValue) * 100);
	return `SYNC_RAND(100) < MaxValueChance ? MaxValue : MinValue;
}

private function XComGameState_Ability GetAbility(StateObjectReference AbilityRef)
{
	local XComGameStateHistory History;
	local XComGameState_BaseObject GameStateObject;

	History = `XCOMHISTORY;
	GameStateObject = History.GetGameStateForObjectID(AbilityRef.ObjectID);

	return XComGameState_Ability(GameStateObject);
}

simulated function GetDamagePreview(StateObjectReference TargetRef, XComGameState_Ability AbilityState, bool bAsPrimaryTarget, out WeaponDamageValue MinDamagePreview, out WeaponDamageValue MaxDamagePreview, out int AllowsShield)
{
	local float fHitChance;
	local int iArmorMitigation, iMinDamage, iMaxDamage;

	// Default behavior
	super.GetDamagePreview(TargetRef, AbilityState, bAsPrimaryTarget, MinDamagePreview, MaxDamagePreview, AllowsShield);

	`Log("");
	`Log("<ReliableDamage.Preview>");

	`Log("IN Damage" @ MinDamagePreview.Damage $ "-" $ MaxDamagePreview.Damage);
	`Log("IN Rupture" @ MinDamagePreview.Rupture, MinDamagePreview.Rupture > 0);
	`Log("IN Shred" @ MinDamagePreview.Shred, MinDamagePreview.Shred > 0);

	fHitChance = GetHitChance(AbilityState, TargetRef);
	iArmorMitigation = GetArmorMitigation(TargetRef, MaxDamagePreview.Damage, MaxDamagePreview.Pierce);

	`Log("ArmorPiercing" @ MaxDamagePreview.Pierce, MaxDamagePreview.Pierce > 0);
	`Log("ArmorMitigation" @ iArmorMitigation, iArmorMitigation > 0);

	iMinDamage = Max(0, MinDamagePreview.Damage - iArmorMitigation);
	iMaxDamage = Max(0, MaxDamagePreview.Damage - iArmorMitigation);

	// Damage
	MinDamagePreview.Damage = iArmorMitigation + FFloor(fHitChance * iMinDamage);
	MaxDamagePreview.Damage = iArmorMitigation + FCeil(fHitChance * iMaxDamage);

	// Rupture
	MinDamagePreview.Rupture = FFloor(fHitChance * MinDamagePreview.Rupture);
	MaxDamagePreview.Rupture = FCeil(fHitChance * MaxDamagePreview.Rupture);

	// Shred
	MinDamagePreview.Shred = FFloor(fHitChance * MinDamagePreview.Shred);
	MaxDamagePreview.Shred = FCeil(fHitChance * MaxDamagePreview.Shred);

	`Log("OUT Damage" @ MinDamagePreview.Damage $ "-" $ MaxDamagePreview.Damage);

	`Log("</ReliableDamage.Preview>");
	`Log("");
}

private function int GetArmorMitigation(StateObjectReference TargetRef, optional int Damage = 0, optional int Pierce = 0)
{
	local Damageable Damageable;
	local XComGameStateHistory History;
	local XComGameState_BaseObject GameStateObject;
	local ArmorMitigationResults ArmorMitigationResults;
	local int iArmorMitigation;

	History = `XCOMHISTORY;
	GameStateObject = History.GetGameStateForObjectID(TargetRef.ObjectID);
	Damageable = Damageable(GameStateObject);
	if(Damageable == None) return 0;

	// Cannot be negative
	iArmorMitigation = Max(0, Damageable.GetArmorMitigation(ArmorMitigationResults));

	// Cannot exceed damage
	iArmorMitigation = Min(Damage, iArmorMitigation);

	// Reduced by Pierce
	iArmorMitigation = Max(0, iArmorMitigation - Pierce);

	return iArmorMitigation;
}
