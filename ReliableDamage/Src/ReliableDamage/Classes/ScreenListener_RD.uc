class ScreenListener_RD extends UIScreenListener config(ReliableDamage);

// This event is triggered after a screen is initialized
event OnInit(UIScreen Screen)
{
    local XComGameState_CampaignSettings Settings;
    local XComGameStateHistory History; 
	
	local XComGameState GameState;
	local XComGameStateContext GameStateContext;

	local bool bIsTactical;

	History = `XCOMHISTORY;
	if(History == None) return;

	GameState = History.GetGameStateFromHistory(History.FindStartStateIndex());
	if(GameState == None) return;

	GameStateContext = GameState.GetContext();
	if(GameStateContext == None) return;

	// Only affect Tactical
	bIsTactical = XComGameStateContext_TacticalGameRule(GameStateContext) != None;
	if(!bIsTactical) return;	

    Settings = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	if(Settings == None) return;	
    
	// Replace all Ability weapon effects by their ReliableDamage version.
	ApplyReliableDamageEffectsToAbilities();

	// Adjust all Weapon Templates to be more reliable (e.g., remove Spread)
	ApplyReliableDamageEffectsToWeapons();

	InitShotHUD(Screen);
}

private function ApplyReliableDamageEffectsToAbilities()
{
	local X2AbilityTemplateManager AbilityTemplateManager;
	local X2AbilityTemplate AbilityTemplate;	
	local X2DataTemplate DataTemplate;
	local X2AbilityToHitCalc_StandardAim StandardAim;
	local X2AbilityToHitCalc_StandardAim_RD StandardAim_RD;		
	local bool bSingleTargetEffectWasReplaced, bMultiTargetEffectWasReplaced;

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();    
	if (AbilityTemplateManager == none) return;    

	// Replace all Abilities that use StandardAim		
	foreach AbilityTemplateManager.IterateTemplates(DataTemplate, None)
	{		
		AbilityTemplate = X2AbilityTemplate(DataTemplate);
		if(AbilityTemplate == None) continue;

		// In the May 2016 update that came with the Alien Hunters DLC,
		// a bunch of "MP" abilities were added, supposedly to be used in Multiplayer.
		// We do not care about those, as we only want to change Singleplayer.		
		if(AbilityTemplate.MP_PerkOverride != '')
		{
			continue;
		} 

		// There is a "Accessed None"-exception in the default X2TargetingMethod_OverTheShoulder class
		// which totally floods the logs (it keeps generating the same error per game tick or something while you are targeting).
		// I have fixed this error with a very minor override.		
		if(AbilityTemplate.TargetingMethod == class'X2TargetingMethod_OverTheShoulder')
		{		
			AbilityTemplate.TargetingMethod = class'X2TargetingMethod_OverTheShoulder_RD';
			`Log("ReliableDamage: " $ "Replaced OverTheShoulder of " $ AbilityTemplate.DataName);
		}
			
		// We only change abilities that use StandardAim
		StandardAim = X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc);
		if(StandardAim == None) continue;

		// Only replace if it is not already replaced
		StandardAim_RD = X2AbilityToHitCalc_StandardAim_RD(AbilityTemplate.AbilityToHitCalc);
		if(StandardAim_RD != None) continue;
		
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
		ApplyWeaponDamage_RD = X2Effect_ApplyWeaponDamage_RD(TargetEffect);
		
		// Not a Weapon Damage Effect
		if(ApplyWeaponDamage == None) continue;
		
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

		// We remove damage spread from the weapon effect as well, it only adds silly RNG.
		// Note this does not remove damage spread from weapons themselves, that is done by modifying
		// the weapon templates rather than the damage effects.
		ApplyWeaponDamage_RD.EffectDamageValue.Spread = 0;

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

		if(ApplyWeaponDamage.EffectDamageValue.Spread > 0) 
		{
			`Log("Found Spread of " @ ApplyWeaponDamage.EffectDamageValue.Spread @ "with ability" @ AbilityTemplate.DataName);	
		}
		
		if(bIsSingle)	AbilityTemplate.AddTargetEffect(ApplyWeaponDamage_RD);			
		else			AbilityTemplate.AddMultiTargetEffect(ApplyWeaponDamage_RD);				

		// We replaced an effect
		bMadeReplacements = true;

		// Build the Log Message
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

private function ApplyReliableDamageEffectsToWeapons()
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

		// Remove Damage Spread
		if(WeaponTemplate.BaseDamage.Spread > 0) 
		{
			`Log(WeaponTemplate.DataName @ ": Spread " @ WeaponTemplate.BaseDamage.Spread @ "-> 0");
			WeaponTemplate.BaseDamage.Spread = 0;
		}		
	}
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