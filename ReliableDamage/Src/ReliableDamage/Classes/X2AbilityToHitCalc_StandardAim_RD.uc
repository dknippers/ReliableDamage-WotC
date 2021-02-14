class X2AbilityToHitCalc_StandardAim_RD extends X2AbilityToHitCalc_StandardAim config(ReliableDamage);

// Used to pass information from damage preview to ShotHUD
// These contain the minimum and maximum damage values
// for the current shot. They are set in ApplyWeaponDamage_RD.GetDamagePreview
var float MinDamage;
var float MaxDamage;

// All config variables are set in XComReliableDamage.ini
// Descriptions available there too
var config bool RoundingEnabled;
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
	if(	ResultContext.HitResult == eHit_Miss  || 
		(!KeepGraze && ResultContext.HitResult == eHit_Graze) || 
		(!KeepCrit && ResultContext.HitResult == eHit_Crit)) 
	{
		ResultContext.HitResult = eHit_Success;
	}

	// Multi Target
	for(i = 0; i < ResultContext.MultiTargetHitResults.Length; i++)
	{
		if(	ResultContext.MultiTargetHitResults[i] == eHit_Miss	 || 
			(!KeepGraze && ResultContext.MultiTargetHitResults[i] == eHit_Graze) ||
			(!KeepCrit && ResultContext.MultiTargetHitResults[i] == eHit_Crit))
		{
			ResultContext.MultiTargetHitResults[i] = eHit_Success;
		}
	}
}				