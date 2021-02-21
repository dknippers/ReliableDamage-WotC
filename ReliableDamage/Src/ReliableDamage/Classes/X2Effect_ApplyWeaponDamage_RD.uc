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

	AbilityContext = GetAbilityContext(ApplyEffectParameters.AbilityStateObjectRef, ApplyEffectParameters.TargetStateObjectRef, NewGameState);

	`Log("");
	`Log("<ReliableDamage.Damage>");

	LogUnit("Source:", AbilityContext.SourceUnit);
	`Log("Ability:" @ AbilityContext.Ability.GetMyTemplateName());
	if(AbilityContext.SourceWeapon != None) `Log("Weapon:" @ AbilityContext.SourceWeapon.GetMyTemplateName());
	if(AbilityContext.TargetUnit != None) LogUnit("Target:", AbilityContext.TargetUnit);
	else if(AbilityContext.TargetObject != None) `Log("Target:" @ AbilityContext.TargetObject.Class);

	LogInt("IN Damage", iDamageOnHit);
	LogInt("IN Rupture", NewRupture, NewRupture != 0);
	LogInt("IN Shred", NewShred, NewShred != 0);

	fHitChance = GetHitChance(AbilityContext.Ability, ApplyEffectParameters.TargetStateObjectRef, fCritChance, fGrazeChance);
	fMissChance = 1.0f - fHitChance;

	fDamageOnHit = fHitChance * iDamageOnHit;

	iDamageOnMiss = GetDamageOnMiss(AbilityContext.Ability);
	fDamageOnMiss = fMissChance * iDamageOnMiss;

	iDamageOnCrit = GetDamageOnCrit(AbilityContext.Ability, ApplyEffectParameters.TargetStateObjectRef, NewGameState);
	fDamageOnCrit = Configuration.AdjustCriticalHits ? fCritChance * iDamageOnCrit : 0.0f;

	// Note this should be negative number; a Graze hit reduces damage taken
	iDamageOnGraze = (iDamageOnHit * GRAZE_DMG_MULT) - iDamageOnHit;
	fDamageOnGraze = Configuration.AdjustGrazeHits ? fGrazeChance * iDamageOnGraze : 0.0f;

	fTotalDamage = fDamageOnHit + fDamageOnMiss + fDamageOnCrit + fDamageOnGraze;

	fRupture = fHitChance * NewRupture;
	fShred = fHitChance * NewShred;

	iTotalDamage = RollForInt(fTotalDamage);
	NewRupture = RollForInt(fRupture);
	NewShred = RollForInt(fShred);

	LogHitChance("fHitChance", fHitChance);
	LogFloat("fDamageOnHit", fDamageOnHit, fDamageOnMiss != 0 || fDamageOnCrit != 0 || fDamageOnGraze != 0);
	LogFloat("fDamageOnMiss", fDamageOnMiss, fDamageOnMiss != 0);
	LogFloat("fDamageOnCrit", fDamageOnCrit, fDamageOnCrit != 0);
	LogFloat("fDamageOnGraze", fDamageOnGraze, fDamageOnGraze != 0);
	LogFloat("fTotalDamage", fTotalDamage);
	LogFloat("fRupture", fRupture, NewRupture != 0);
	LogFloat("fShred", fShred, NewShred != 0);

	LogInt("OUT Damage", iTotalDamage);
	LogInt("OUT Rupture", NewRupture, fRupture != 0);
	LogInt("OUT Shred", NewShred, fShred != 0);

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
	fDamageOnCrit = Configuration.AdjustCriticalHits ? fCritChance * GetDamageOnCrit(AbilityState, TargetRef) : 0.0f;

	iArmorMitigation = GetArmorMitigation(TargetRef, MaxDamagePreview.Damage, MaxDamagePreview.Pierce);

	iMinDamage = Max(0, MinDamagePreview.Damage - iArmorMitigation);
	iMaxDamage = Max(0, MaxDamagePreview.Damage - iArmorMitigation);

	fMinDamage = fHitChance * iMinDamage;
	fMaxDamage = fHitChance * iMaxDamage;

	iMinDamageOnGraze = (iMinDamage * GRAZE_DMG_MULT) - iMinDamage;
	iMaxDamageOnGraze = (iMaxDamage * GRAZE_DMG_MULT) - iMaxDamage;

	fMinDamageOnGraze = Configuration.AdjustGrazeHits ? fGrazeChance * iMinDamageOnGraze : 0.0f;
	fMaxDamageOnGraze = Configuration.AdjustGrazeHits ? fGrazeChance * iMaxDamageOnGraze : 0.0f;

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

private function int GetDamageOnCrit(XComGameState_Ability Ability, StateObjectReference TargetRef, optional XComGameState NewGameState)
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
	SourceUnit = GetUnit(Ability.OwnerStateObject, NewGameState);
	TargetUnit = GetUnit(TargetRef, NewGameState);
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

private function int SumCrit(ApplyDamageInfo DamageInfo)
{
	return
		DamageInfo.BaseDamageValue.Crit +
		DamageInfo.ExtraDamageValue.Crit +
		DamageInfo.BonusEffectDamageValue.Crit +
		DamageInfo.AmmoDamageValue.Crit +
		DamageInfo.UpgradeDamageValue.Crit;
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
