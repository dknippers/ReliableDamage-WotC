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
	local float fHitChance, fMissChance, fCritChance, fGrazeChance, fTotalDamage, fDamageOnHit, fDamageOnMiss, fDamageOnCrit, fDamageOnGraze, fDamageOnPlusOne, fShred, fRupture;
	local AbilityGameStateContext AbilityContext;
	local ApplyDamageInfo DamageInfo;

	// Calculate damage as usual
	iDamageOnHit = super.CalculateDamageAmount(ApplyEffectParameters, ArmorMitigation, NewRupture, NewShred, AppliedDamageTypes, bAmmoIgnoresShields, bFullyImmune, SpecialDamageMessages, NewGameState);

	if(ApplyEffectParameters.AbilityResultContext.HitResult != eHit_Success)
	{
		// We only adjust damage for regular hits. Do not touch anything else.
		return iDamageOnHit;
	}

	AbilityContext = GetAbilityContext(ApplyEffectParameters.AbilityStateObjectRef, ApplyEffectParameters.TargetStateObjectRef, NewGameState);
	DamageInfo = CalculateDamageInfo(AbilityContext);

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

	iDamageOnCrit = GetDamageOnCrit(AbilityContext, DamageInfo);
	fDamageOnCrit = Configuration.AdjustCriticalHits ? fCritChance * iDamageOnCrit : 0.0f;

	// Note this should be negative number; a Graze hit reduces damage taken
	iDamageOnGraze = (iDamageOnHit * GRAZE_DMG_MULT) - iDamageOnHit;
	fDamageOnGraze = Configuration.AdjustGrazeHits ? fGrazeChance * iDamageOnGraze : 0.0f;

	fDamageOnPlusOne = Configuration.AdjustPlusOne ? GetPlusOneExpectedValue(DamageInfo) : 0.0f;

	fTotalDamage = fDamageOnHit + fDamageOnMiss + fDamageOnCrit + fDamageOnGraze + fDamageOnPlusOne;

	fRupture = fHitChance * NewRupture;
	fShred = fHitChance * NewShred;

	iTotalDamage = RollForInt(fTotalDamage);
	NewRupture = RollForInt(fRupture);
	NewShred = RollForInt(fShred);

	LogHitChance("fHitChance", fHitChance);
	LogFloat("fDamageOnHit", fDamageOnHit, fDamageOnMiss != 0 || fDamageOnCrit != 0 || fDamageOnGraze != 0 || fDamageOnPlusOne != 0);
	LogFloat("fDamageOnMiss", fDamageOnMiss, fDamageOnMiss != 0);
	LogFloat("fDamageOnCrit", fDamageOnCrit, fDamageOnCrit != 0);
	LogFloat("fDamageOnGraze", fDamageOnGraze, fDamageOnGraze != 0);
	LogFloat("fDamageOnPlusOne", fDamageOnPlusOne, fDamageOnPlusOne != 0);
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
	local float fHitChance, fMissChance, fCritChance, fGrazeChance, fMinDamage, fMaxDamage, fDamageOnMiss, fDamageOnCrit, fMinDamageOnGraze, fMaxDamageOnGraze, fDamageOnPlusOne;
	local int iArmorMitigation, iMinDamage, iMaxDamage, iMinDamageOnGraze, iMaxDamageOnGraze, iMaxPlusOneDamage, iRuptureDamage;
	local ApplyDamageInfo DamageInfo;
	local AbilityGameStateContext AbilityContext;

	// Default behavior
	super.GetDamagePreview(TargetRef, AbilityState, bAsPrimaryTarget, MinDamagePreview, MaxDamagePreview, AllowsShield);

	AbilityContext = GetAbilityContext(AbilityState.GetReference(), TargetRef);
	DamageInfo = CalculateDamageInfo(AbilityContext);

	fHitChance = GetHitChance(AbilityState, TargetRef, fCritChance, fGrazeChance);
	fMissChance = 1.0f - fHitChance;
	fDamageOnMiss = fMissChance * GetDamageOnMiss(AbilityState);
	fDamageOnCrit = Configuration.AdjustCriticalHits ? fCritChance * GetDamageOnCrit(AbilityContext, DamageInfo) : 0.0f;
	fDamageOnPlusOne = Configuration.AdjustPlusOne ? GetPlusOneExpectedValue(DamageInfo, iMaxPlusOneDamage) : 0.0f;

	iArmorMitigation = GetArmorMitigation(TargetRef, MaxDamagePreview.Damage, MaxDamagePreview.Pierce);

	// XCOM adds Rupture bonus damage later as a constant bonus to both Minimum and Maximum damage.
	// We want to scale this bonus like all other damage so we add it here to both iMin & iMax damage
	// to scale it and at the end remove the fixed Rupture value to end up at the correct amount in the UI.
	iRuptureDamage = AbilityContext.TargetUnit != None ? AbilityContext.TargetUnit.GetRupturedValue() : 0;

	// We also include the preview Rupture as this is immediately applied to the target as damage as well.
	// This is something that XCOM leaves out by default as well and is incorrect so we fix that here.
	iMinDamage = Max(0, MinDamagePreview.Damage - iArmorMitigation + iRuptureDamage + MinDamagePreview.Rupture);
	iMaxDamage = Max(0, MaxDamagePreview.Damage - iArmorMitigation + iRuptureDamage + MaxDamagePreview.Rupture - iMaxPlusOneDamage);

	fMinDamage = fHitChance * iMinDamage;
	fMaxDamage = fHitChance * iMaxDamage;

	iMinDamageOnGraze = (iMinDamage * GRAZE_DMG_MULT) - iMinDamage;
	iMaxDamageOnGraze = (iMaxDamage * GRAZE_DMG_MULT) - iMaxDamage;

	fMinDamageOnGraze = Configuration.AdjustGrazeHits ? fGrazeChance * iMinDamageOnGraze : 0.0f;
	fMaxDamageOnGraze = Configuration.AdjustGrazeHits ? fGrazeChance * iMaxDamageOnGraze : 0.0f;

	// Damage
	MinDamagePreview.Damage = FFloor(fMinDamage + fDamageOnMiss + fDamageOnCrit + fMinDamageOnGraze + fDamageOnPlusOne) + iArmorMitigation - iRuptureDamage;
	MaxDamagePreview.Damage = FCeil(fMaxDamage + fDamageOnMiss + fDamageOnCrit + fMaxDamageOnGraze + fDamageOnPlusOne) + iArmorMitigation - iRuptureDamage;

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
		TotalPlusOne += DamageInfo.BaseDamageValue.PlusOne;
	}

	if(DamageInfo.ExtraDamageValue.PlusOne > 0)
	{
		MaxDamage++;
		TotalPlusOne += DamageInfo.ExtraDamageValue.PlusOne;
	}

	if(DamageInfo.BonusEffectDamageValue.PlusOne > 0)
	{
		MaxDamage++;
		TotalPlusOne += DamageInfo.BonusEffectDamageValue.PlusOne;
	}

	if(DamageInfo.AmmoDamageValue.PlusOne > 0)
	{
		MaxDamage++;
		TotalPlusOne += DamageInfo.AmmoDamageValue.PlusOne;
	}

	if(DamageInfo.UpgradeDamageValue.PlusOne > 0)
	{
		MaxDamage++;
		TotalPlusOne += DamageInfo.UpgradeDamageValue.PlusOne;
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
