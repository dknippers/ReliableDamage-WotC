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
	local float fHitChance, fDamage;	
	
	// Calculate damage as usual
	iDamage = Original.CalculateDamageAmount(ApplyEffectParameters, ArmorMitigation, NewRupture, NewShred, AppliedDamageTypes, bAmmoIgnoresShields, bFullyImmune, SpecialDamageMessages, NewGameState);

	`Log("DEFAULT Damage =" @ iDamage);

	// Update calculated damage based on hit chance
	fHitChance = ApplyEffectParameters.AbilityResultContext.CalculatedHitChance / 100.0;
	fDamage = fHitChance * iDamage;

	iDamage = RollForInt(fDamage);
	
	`Log("fHitChance =" @ fHitChance);
	`Log("fDamage =" @ fDamage);
	`Log("MODIFIED Damage =" @ iDamage);

	return iDamage;
}

private function float GetHitChance(XComGameState_Ability Ability, StateObjectReference TargetRef)
{	
	local ShotBreakdown Breakdown;
	local int HitChance;
		
	Ability.LookupShotBreakdown(Ability.OwnerStateObject, TargetRef, Ability.GetReference(), Breakdown);

	if(Breakdown.bIsMultishot)
	{
		HitChance = Breakdown.MultiShotHitChance;
	}
	else
	{		
		HitChance = Breakdown.ResultTable[eHit_Success] + Breakdown.ResultTable[eHit_Crit] + Breakdown.ResultTable[eHit_Graze];
	}

	HitChance = Min(100, HitChance);

	// Return HitChance as a value between 0.0 and 1.0
	return HitChance / 100.0;
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
	local float fHitChance, fMinDamage, fMaxDamage;

	if(OriginalToggleCondition == None) return;	
	
	// Flip to succeed to make Original.GetDamagePreview() work
	OriginalToggleCondition.Succeed = true;

	// Default behavior
	Original.GetDamagePreview(TargetRef, AbilityState, bAsPrimaryTarget, MinDamagePreview, MaxDamagePreview, AllowsShield);

	// Flip back to fail
	OriginalToggleCondition.Succeed = false;

	// `Log("DEFAULT MinDamagePreview.Damage" @ MinDamagePreview.Damage);
	// `Log("DEFAULT MaxDamagePreview.Damage" @ MaxDamagePreview.Damage);

	fHitChance = GetHitChance(AbilityState, TargetRef);

	fMinDamage = fHitChance * MinDamagePreview.Damage;
	fMaxDamage = fHitChance * MaxDamagePreview.Damage;

	MinDamagePreview.Damage = FFloor(fMinDamage);
	MaxDamagePreview.Damage = FCeil(fMaxDamage);
	
	// `Log("PREVIEW fHitChance" @ fHitChance);
	// `Log("PREVIEW fMinDamage" @ fMinDamage);
	// `Log("PREVIEW fMaxDamage" @ fMaxDamage);
	// `Log("MODIFIED MinDamagePreview.Damage" @ MinDamagePreview.Damage);
	// `Log("MODIFIED MaxDamagePreview.Damage" @ MaxDamagePreview.Damage);	
}
