class Main extends UIScreenListener config(ReliableDamage);

var config bool RemoveSpread;

// This event is triggered after a screen is initialized
event OnInit(UIScreen Screen)
{
    local XComGameStateHistory History; 	
	local XComGameState GameState;
	local XComGameStateContext GameStateContext;	

	History = `XCOMHISTORY;
	if(History == None) return;

	GameState = History.GetGameStateFromHistory(History.FindStartStateIndex());
	if(GameState == None) return;

	GameStateContext = GameState.GetContext();
	if(GameStateContext == None) return;

	// Only affect Tactical
	if(XComGameStateContext_TacticalGameRule(GameStateContext) == None) return;

	InitReliableDamage();
	InitShotHUD(Screen);	
}

private function InitReliableDamage()
{
	local X2AbilityTemplateManager AbilityTemplateManager;
    local X2AbilityTemplate AbilityTemplate;    
    local X2DataTemplate DataTemplate;

	if(RemoveSpread) RemoveDamageSpreadFromWeapons();	

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();    
	if (AbilityTemplateManager == none) return;    

	foreach AbilityTemplateManager.IterateTemplates(DataTemplate, None)
	{		
		AbilityTemplate = X2AbilityTemplate(DataTemplate);
		if(AbilityTemplate == None) continue;

		if(RemoveSpread) RemoveDamageSpreadFromAbility(AbilityTemplate);

		ApplyReliableDamageEffectsToAbility(AbilityTemplate);
	}
}

private function ApplyReliableDamageEffectsToAbility(X2AbilityTemplate AbilityTemplate)
{
	local X2AbilityToHitCalc_StandardAim StandardAim;
	local X2AbilityToHitCalc_StandardAim_RD StandardAim_RD;		
	local bool bSingleTargetEffectWasReplaced, bMultiTargetEffectWasReplaced;	

	// In the May 2016 update that came with the Alien Hunters DLC,
	// a bunch of "MP" abilities were added, supposedly to be used in Multiplayer.
	// We do not care about those, as we only want to change Singleplayer.		
	if(AbilityTemplate.MP_PerkOverride != '') return;
			
	// We only change abilities that use StandardAim
	StandardAim = X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc);
	if(StandardAim == None) return;

	// Only replace if it is not already replaced
	StandardAim_RD = X2AbilityToHitCalc_StandardAim_RD(AbilityTemplate.AbilityToHitCalc);
	if(StandardAim_RD != None) return;	
		
	// Do not touch abilities that have any displacement effects.
	// Making those abilities hit 100% of the time is extremely imbalanced.
	if(HasDisplacementEffect(AbilityTemplate)) return;
		
	// Replace Single Target Weapon Effects
	bSingleTargetEffectWasReplaced = ReplaceWeaponEffects(AbilityTemplate, true);

	// Replace Multi Target Weapon Effects
	bMultiTargetEffectWasReplaced = ReplaceWeaponEffects(AbilityTemplate, false);

	// If a single and/or multi weapon effect was replaced, use our StandardAim for this Ability.
	// We require a weapon effect since we don't want to use our Reliable Damage
	// for abilities (like Viper's Get Over Here) that use StandardAim but do not have
	// an Apply Weapon Damage Effect.
	if(bSingleTargetEffectWasReplaced || bMultiTargetEffectWasReplaced)
	{
		// Any Knockback effect should always run last, otherwise it will be interrupted by another effect
		// If we have replaced a single or multi effect (by adding our effect last in the list), we therefore
		// also have to fix any knockback effects by making sure they are placed at the end of the list of effects.			
		// We do this for both Single and Multi effects again.
		FixKnockbackEffects(AbilityTemplate, true);
		FixKnockbackEffects(AbilityTemplate, false);

		// Replace AbilityToHitCalc with our own.
		// Copy all properties of StandardAim
		StandardAim_RD = new class'X2AbilityToHitCalc_StandardAim_RD';
		StandardAim_RD.Clone(StandardAim);

		AbilityTemplate.AbilityToHitCalc = StandardAim_RD;
	}	
}

private function bool ReplaceWeaponEffects(X2AbilityTemplate AbilityTemplate, bool bIsSingle)
{
	local X2Effect TargetEffect;
	local array<X2Effect> TargetEffects;
	local X2Effect_ApplyWeaponDamage ApplyWeaponDamage;
	local X2Effect_ApplyWeaponDamage_RD ApplyWeaponDamage_RD;				
	local bool bMadeReplacements;
	local int iMultiEffectIndex;
	local string LogMessage; // Log when a Single and/or Multi Effect is replaced

	bMadeReplacements = false;

	// Single Target and Multi Target effects are stored in different Arrays
	TargetEffects = bIsSingle ? AbilityTemplate.AbilityTargetEffects : AbilityTemplate.AbilityMultiTargetEffects;
	
	foreach TargetEffects(TargetEffect)
	{
		// Only look at Effects that work on hit and deal damage
		if(!TargetEffect.bApplyOnHit || !TargetEffect.bAppliesDamage) continue;

		// Now let's see if it's a Weapon Damage Effect
		ApplyWeaponDamage = X2Effect_ApplyWeaponDamage(TargetEffect);		
		
		// Not a Weapon Damage Effect
		if(ApplyWeaponDamage == None) continue;

		ApplyWeaponDamage_RD = X2Effect_ApplyWeaponDamage_RD(TargetEffect);
		
		// If we find any RD Weapon Effect we know we have already
		// been through the whole list. Just quit right here.
		if(ApplyWeaponDamage_RD != None) return bMadeReplacements;			

		// We now know this is a Weapon Damage effect, 
		// and is not an instance of our ApplyWeaponDamage_RD.
		// We should replace this one.

		// Add the Reliable Damage version of this effect
		// Make sure to copy all important properties of this 
		// damage effect!
		ApplyWeaponDamage_RD = new class'X2Effect_ApplyWeaponDamage_RD';		
		ApplyWeaponDamage_RD.Clone(ApplyWeaponDamage);

		// Disable damage from the original Weapon Effect.			
		// This is done as a workaround for the fact we cannot actually
		// remove it from the list of TargetEffects						
		ApplyWeaponDamage.ApplyChance         = 0;
		ApplyWeaponDamage.ApplyChanceFn       = None;
		ApplyWeaponDamage.bAppliesDamage      = false;	
		ApplyWeaponDamage.bApplyOnHit         = false;
		ApplyWeaponDamage.bApplyOnMiss        = false;		
		ApplyWeaponDamage.bApplyToWorldOnHit  = false;
		ApplyWeaponDamage.bApplyToWorldOnMiss = false;		
		ApplyWeaponDamage.TargetConditions.Length = 0;		
		
		if(bIsSingle)	AbilityTemplate.AddTargetEffect(ApplyWeaponDamage_RD);			
		else			AbilityTemplate.AddMultiTargetEffect(ApplyWeaponDamage_RD);				

		bMadeReplacements = true;

		LogMessage = "ReliableDamage:";

		// It happens that the same ApplyWeaponDamage instance is used as both a Single Target
		// and a Multi Target effect. We replace Single Target effects first, so we only have to look
		// if a found Single Effect is used as a Multi Effect as well
		if(bIsSingle)
		{
			LogMessage @= "Single";

			iMultiEffectIndex = AbilityTemplate.AbilityMultiTargetEffects.Find(ApplyWeaponDamage);
			if(iMultiEffectIndex >= 0)
			{
				// It was also used as a Multi Effect.
				// That effect is the same instance as ApplyWeaponDamage,
				// so it is already disabled. The only thing left is to
				// add our RD version to the Multi Effects as well.
				AbilityTemplate.AddMultiTargetEffect(ApplyWeaponDamage_RD);				

				LogMessage @= "and Multi";
			}					
		}		
		else 
		{
			LogMessage @= "Multi";
		}

		LogMessage @= "Effect added to" @ AbilityTemplate.DataName @ "to replace" @ ApplyWeaponDamage;

		`Log(LogMessage);		
	}					

	return bMadeReplacements;
}

// Make sure Knockback Effects are present at the end of the list of Effects,
// otherwise they do not run at all (or probably they do, but are interrupted right after
// they start).
private function FixKnockbackEffects(X2AbilityTemplate AbilityTemplate, bool bIsSingle)
{
	local X2Effect TargetEffect;
	local array<X2Effect> TargetEffects;
	local X2Effect_Knockback Knockback;

	// Single Target and Multi Target effects are stored in different Arrays
	TargetEffects = bIsSingle ? AbilityTemplate.AbilityTargetEffects : AbilityTemplate.AbilityMultiTargetEffects;
	
	foreach TargetEffects(TargetEffect)
	{
		// Is this a Knockback effect?
		Knockback = X2Effect_Knockback(TargetEffect);		
		
		// Not a Knockback
		if(Knockback == None) continue;		

		// This is a Knockback effect.
		// Just add it again to the end of the list.
		// We tried making a new X2Effect_Knockback instance which copied all properties
		// from the original Knockback, add that to the list and disable the original Knockback,
		// like we do with ApplyWeaponDamage. However, that didn't work as well (soldiers were being
		// tossed all over the place instead of a few meters backwards), whereas this works perfectly. 
		// It is a bit weird that there are now 2 active Knockback effects (or technically 1 instance that appears
		// in the list 2 times) but that does not seem to matter too much so I'll let it slide.
		if(bIsSingle)	AbilityTemplate.AddTargetEffect(Knockback);			
		else			AbilityTemplate.AddMultiTargetEffect(Knockback);				
	}					
}

private function RemoveDamageSpreadFromWeapons()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2WeaponTemplate WeaponTemplate;	
	local X2DataTemplate DataTemplate;	

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	if (ItemTemplateManager == none) return;    

	// Loop through all weapons in the game
	foreach ItemTemplateManager.IterateTemplates(DataTemplate, None)
	{		
		WeaponTemplate = X2WeaponTemplate(DataTemplate);
		if(WeaponTemplate == None) continue;

		RemoveWeaponSpread(WeaponTemplate);
	}
}

private function RemoveWeaponSpread(X2WeaponTemplate WeaponTemplate) 
{
	local WeaponDamageValue ExtraDamage;

	WeaponTemplate.BaseDamage.Spread = 0;	

	foreach WeaponTemplate.ExtraDamage(ExtraDamage)
	{
		ExtraDamage.Spread = 0;		
	}
}

private function RemoveDamageSpreadFromAbility(X2AbilityTemplate AbilityTemplate)
{
	RemoveDamageSpreadFromWeaponEffects(AbilityTemplate.AbilityTargetEffects);
	RemoveDamageSpreadFromWeaponEffects(AbilityTemplate.AbilityMultiTargetEffects);
}

private function RemoveDamageSpreadFromWeaponEffects(array<X2Effect> WeaponEffects)
{
	local X2Effect WeaponEffect;
	local X2Effect_ApplyWeaponDamage WeaponDamageEffect;

	foreach WeaponEffects(WeaponEffect)
	{
		WeaponDamageEffect = X2Effect_ApplyWeaponDamage(WeaponEffect);
		if(WeaponDamageEffect != None) WeaponDamageEffect.EffectDamageValue.Spread = 0;		
	}
}

// Returns true if the list of effects contains an effect that displaces
// target or source, such as the GetOverHere effect of Viper or Skirimisher
private function bool HasDisplacementEffect(X2AbilityTemplate AbilityTemplate) {
	return 
		ContainsDisplacementEffect(AbilityTemplate.AbilityTargetEffects) || 
		ContainsDisplacementEffect(AbilityTemplate.AbilityMultiTargetEffects);
}
 
private function bool ContainsDisplacementEffect(array<X2Effect> TargetEffects) {		
	local X2Effect TargetEffect;

	foreach TargetEffects(TargetEffect) 
	{
		// Test known displacement effects
		if(X2Effect_GetOverHere(TargetEffect) != None) return true;
		if(X2Effect_GetOverThere(TargetEffect) != None) return true;
	}

	return false;
}

// Applies our custom ShotHUD to the Screen if it was not done already
private function InitShotHUD(UIScreen screen)
{
	local UITacticalHUD TacticalHUD;
	local UITacticalHUD_ShotHUD_RD ShotHUD_RD;

	// Apply our modified ShotHUD	
	TacticalHUD = UITacticalHUD(Screen);	

	// No HUD? We're done.
	if(TacticalHUD == None) return;

	// Is the ShotHUD already ours?
	ShotHUD_RD = UITacticalHUD_ShotHUD_RD(TacticalHUD.m_kShotHUD);
	
	// Yes, so we don't have to initialize it again
	if(ShotHUD_RD != None) return;

	// We have not yet initialized ours
	// Remove the existing one
	TacticalHUD.m_kShotHUD.Remove();
	
	// And apply ours
	TacticalHUD.m_kShotHUD = TacticalHUD.Spawn(class'UITacticalHUD_ShotHUD_RD', Screen).InitShotHUD();

	// Shotwings need to be initialized too	
	TacticalHUD.m_kShotInfoWings = TacticalHUD.Spawn(class'UITacticalHUD_ShotWings', Screen).InitShotWings();
}

defaultproperties
{
    // Leaving this assigned to none will cause every screen to trigger its signals on this class
    ScreenClass=None
}