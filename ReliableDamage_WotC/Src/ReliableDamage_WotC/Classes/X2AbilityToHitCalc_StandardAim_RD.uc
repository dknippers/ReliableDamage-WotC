class X2AbilityToHitCalc_StandardAim_RD extends X2AbilityToHitCalc_StandardAim;

var const Configuration Configuration;

// Copies all properties from the given X2AbilityToHitCalc_StandardAim
function Clone(X2AbilityToHitCalc_StandardAim Source)
{
	// X2AbilityToHitCalc
	HitModifiers = Source.HitModifiers;

	// X2AbilityToHitCalc_StandardAim
	bIndirectFire = Source.bIndirectFire;
	bMeleeAttack = Source.bMeleeAttack;
	bReactionFire = Source.bReactionFire;
	bAllowCrit = Source.bAllowCrit;
	bHitsAreCrits = Source.bHitsAreCrits;
	bMultiTargetOnly = Source.bMultiTargetOnly;
	bOnlyMultiHitWithSuccess = Source.bOnlyMultiHitWithSuccess;
	bGuaranteedHit = Source.bGuaranteedHit;
	bIgnoreCoverBonus = Source.bIgnoreCoverBonus;
	FinalMultiplier = Source.FinalMultiplier;

	BuiltInHitMod = Source.BuiltInHitMod;
	BuiltInCritMod = Source.BuiltInCritMod;
}

function RollForAbilityHit(XComGameState_Ability kAbility, AvailableTarget kTarget, out AbilityResultContext ResultContext)
{
	local int i;

	// Default behavior
	super.RollForAbilityHit(kAbility, kTarget, ResultContext);

	assert(kTarget.AdditionalTargets.Length == ResultContext.MultiTargetHitResults.Length);

	// Single Target
	if(ShouldChangeToHit(kTarget.PrimaryTarget, ResultContext.HitResult))
	{
		ResultContext.HitResult = eHit_Success;
	}

	// Multi Target
	for(i = 0; i < ResultContext.MultiTargetHitResults.Length; i++)
	{
		if(ShouldChangeToHit(kTarget.AdditionalTargets[i], ResultContext.MultiTargetHitResults[i]))
		{
			ResultContext.MultiTargetHitResults[i] = eHit_Success;
		}
	}
}

private function bool ShouldChangeToHit(StateObjectReference TargetRef, EAbilityHitResult HitResult)
{
	if(!Configuration.ApplyVsTheLost && class'X2Effect_ApplyWeaponDamage_RD'.static.UnitIsTheLost(TargetRef))
	{
		return false;
	}

	switch(HitResult)
	{
		case eHit_Miss: return true;

		case ehit_Crit: return Configuration.AdjustCriticalHits;
		case eHit_Graze: return Configuration.AdjustGrazeHits;

		default: return false;
	}
}

function int GetShotBreakdown(XComGameState_Ability kAbility, AvailableTarget kTarget, optional out ShotBreakdown m_ShotBreakdown, optional bool bDebugLog = false)
{
	local int HitChance;
	local ShotModifierInfo ModifierInfo;
     
	HitChance = super.GetShotBreakdown(kAbility, kTarget, m_ShotBreakdown, bDebugLog);
 
	ModifierInfo.Value = 0;
	ModifierInfo.Reason = "85% | 4-5 | 15%";
	ModifierInfo.ModType = eHit_Success;
 
	m_ShotBreakdown.Modifiers.AddItem(ModifierInfo);
 
	return HitChance;
}

defaultproperties
{
	Begin Object Class=Configuration Name=Configuration
	End Object
	Configuration=Configuration
}
