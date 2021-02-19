class X2AbilityToHitCalc_StandardAim_RD extends X2AbilityToHitCalc_StandardAim config(ReliableDamage);

// All config variables are set in XComReliableDamage.ini
// Descriptions available there too
var config int OverwatchRemovalMinimumDamage;
var config int OverwatchRemovalMinimumHitChance;
var config bool KeepGraze;
var config bool KeepCrit;

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
	FinalMultiplier = Source.FinalMultiplier;

	BuiltInHitMod = Source.BuiltInHitMod;
	BuiltInCritMod = Source.BuiltInCritMod;
}

function RollForAbilityHit(XComGameState_Ability kAbility, AvailableTarget kTarget, out AbilityResultContext ResultContext)
{
	local int i;

	// Default behavior
	super.RollForAbilityHit(kAbility, kTarget, ResultContext);

	// However, a regular Miss, Graze, or Crit cannot occur (since we incorporate those effects into all hits).
	// Just note there appear to be some special cases (eHit_Untouchable, eHit_LightningReflexes)
	// that we don't necessarily want to touch. So we simply only change eHit_Miss, eHit_Graze, and eHit_Crit to eHit_Success.

	// Single Target
	if(ShouldChangeToHit(ResultContext.HitResult))
	{
		ResultContext.HitResult = eHit_Success;
	}

	// Multi Target
	for(i = 0; i < ResultContext.MultiTargetHitResults.Length; i++)
	{
		if(ShouldChangeToHit(ResultContext.MultiTargetHitResults[i]))
		{
			ResultContext.MultiTargetHitResults[i] = eHit_Success;
		}
	}
}

private function bool ShouldChangeToHit(EAbilityHitResult hitResult) {
	return
		hitResult == eHit_Miss ||
		(!KeepGraze && hitResult == eHit_Graze) ||
		(!KeepCrit && hitResult == eHit_Crit);
}
