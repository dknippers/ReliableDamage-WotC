class Main extends Object;

var const Configuration Configuration;

delegate WithEffect(X2Effect Effect);
delegate WithAbilityTemplate(X2AbilityTemplate AbilityTemplate);

function InitReliableDamage()
{
	if(Configuration.RemoveDamageSpread)
	{
		RemoveDamageSpreadFromWeapons();
	}

	if(Configuration.ApplyAmmoEffectsBasedOnHitChance)
	{
		ApplyAmmoEffectsBasedOnHitChance();
	}

	`Log("");
	`Log("<ReliableDamage.ReplaceWeaponEffects>");

	ForEachAbilityTemplate(MaybeUpdateAbility);

	`Log("</ReliableDamage.ReplaceWeaponEffects>");
	`Log("");
}

private function MaybeUpdateAbility(X2AbilityTemplate AbilityTemplate)
{
	local X2AbilityToHitCalc_StandardAim StandardAim;
	local X2AbilityToHitCalc_StandardAim_RD StandardAim_RD;
	local bool bSingleTargetEffectWasReplaced, bMultiTargetEffectWasReplaced;

	// We only change abilities that use StandardAim
	StandardAim = X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc);
	if(StandardAim == None) return;

	// Only replace if it is not already replaced
	StandardAim_RD = X2AbilityToHitCalc_StandardAim_RD(AbilityTemplate.AbilityToHitCalc);
	if(StandardAim_RD != None) return;

	// Do not touch abilities that have any displacement effects.
	// Making those abilities hit 100% of the time is extremely imbalanced.
	if(HasDisplacementEffect(AbilityTemplate)) return;

	if(Configuration.RemoveDamageSpread) RemoveDamageSpreadFromAbility(AbilityTemplate);

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
		FixKnockbackEffects(AbilityTemplate);

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
	local bool bMadeReplacements, bIsSingleAndMulti;
	local string LogPrefix;

	bMadeReplacements = false;

	// Single Target and Multi Target effects are stored in different Arrays
	TargetEffects = bIsSingle ? AbilityTemplate.AbilityTargetEffects : AbilityTemplate.AbilityMultiTargetEffects;

	foreach TargetEffects(TargetEffect)
	{
		// Only look at Effects that work on hit and deal damage
		if(!TargetEffect.bApplyOnHit || !TargetEffect.bAppliesDamage) continue;

		ApplyWeaponDamage = X2Effect_ApplyWeaponDamage(TargetEffect);
		if(ApplyWeaponDamage == None || ApplyWeaponDamage.bIgnoreBaseDamage) continue;

		ApplyWeaponDamage_RD = X2Effect_ApplyWeaponDamage_RD(TargetEffect);
		if(ApplyWeaponDamage_RD != None) continue;

		ApplyWeaponDamage_RD = CloneWeaponDamage(ApplyWeaponDamage);

		bIsSingleAndMulti = false;

		if(bIsSingle)
		{
			AbilityTemplate.AddTargetEffect(ApplyWeaponDamage_RD);

			if(AbilityTemplate.AbilityMultiTargetEffects.Find(ApplyWeaponDamage) >= 0)
			{
				// The same instance of ApplyWeaponDamage was also used as a Multi Effect.
				// It is already disabled so we just add our RD version as a Multi Effect.
				AbilityTemplate.AddMultiTargetEffect(ApplyWeaponDamage_RD);
				bIsSingleAndMulti = true;
			}
		}
		else
		{
			AbilityTemplate.AddMultiTargetEffect(ApplyWeaponDamage_RD);
		}

		// The original cannot actually be removed from the list of target effects
		// so we will disable it instead.
		DisableWeaponDamage(ApplyWeaponDamage);

		bMadeReplacements = true;

		LogPrefix = bIsSingleAndMulti ? "*" : bIsSingle ? "S" : "M";
		`Log("[" $ LogPrefix $ "]" @ AbilityTemplate.DataName $ "." $ ApplyWeaponDamage);
	}

	return bMadeReplacements;
}

private function X2Effect_ApplyWeaponDamage_RD CloneWeaponDamage(X2Effect_ApplyWeaponDamage ApplyWeaponDamage)
{
	local X2Effect_ApplyWeaponDamage_RD ApplyWeaponDamage_RD;

	ApplyWeaponDamage_RD = new class'X2Effect_ApplyWeaponDamage_RD';
	ApplyWeaponDamage_RD.Clone(ApplyWeaponDamage);

	return ApplyWeaponDamage_RD;
}

private function DisableWeaponDamage(X2Effect_ApplyWeaponDamage ApplyWeaponDamage)
{
	local X2Condition_Toggle_RD ToggleCondition;

	ToggleCondition = new class'X2Condition_Toggle_RD';
	ToggleCondition.Succeed = false;

	ApplyWeaponDamage.TargetConditions.AddItem(ToggleCondition);
	ApplyWeaponDamage.bAppliesDamage = false;
	ApplyWeaponDamage.bApplyOnHit = false;
	ApplyWeaponDamage.HideVisualizationOfResultsAdditional.AddItem('AA_Success');
}

// Make sure Knockback Effects are present at the end of the list of Effects,
// otherwise they do not run at all (or probably they do, but are interrupted right after
// they start).
private function FixKnockbackEffects(X2AbilityTemplate AbilityTemplate)
{
	ForEachKnockback(AbilityTemplate.AbilityTargetEffects, AbilityTemplate.AddTargetEffect);
	ForEachKnockback(AbilityTemplate.AbilityMultiTargetEffects, AbilityTemplate.AddMultiTargetEffect);
}

private function ForEachKnockback(array<X2Effect> TargetEffects, delegate<WithEffect> WithEffect)
{
	local X2Effect TargetEffect;
	local X2Effect_Knockback Knockback;

	foreach TargetEffects(TargetEffect)
	{
		Knockback = X2Effect_Knockback(TargetEffect);
		if(Knockback != None) WithEffect(Knockback);
	}
}

private function ForEachAbilityTemplate(delegate<WithAbilityTemplate> WithAbilityTemplate)
{
	local X2AbilityTemplateManager AbilityTemplateManager;
	local X2AbilityTemplate AbilityTemplate;
	local X2DataTemplate DataTemplate;
	local array<X2AbilityTemplate> AbilityTemplates;

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	if (AbilityTemplateManager == none) return;

	foreach AbilityTemplateManager.IterateTemplates(DataTemplate, None)
	{
		AbilityTemplate = X2AbilityTemplate(DataTemplate);
		if(AbilityTemplate == None) continue;

		AbilityTemplateManager.FindAbilityTemplateAllDifficulties(AbilityTemplate.DataName, AbilityTemplates);

		foreach AbilityTemplates(AbilityTemplate)
		{
			WithAbilityTemplate(AbilityTemplate);
		}
	}
}

private function RemoveDamageSpreadFromWeapons()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2WeaponTemplate WeaponTemplate;
	local X2DataTemplate DataTemplate;
	local array<X2DataTemplate> DataTemplates;

	`Log("");
	`Log("<ReliableDamage.RemoveDamageSpread />");

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	if (ItemTemplateManager == none) return;

	// Loop through all weapons in the game
	foreach ItemTemplateManager.IterateTemplates(DataTemplate)
	{
		WeaponTemplate = X2WeaponTemplate(DataTemplate);
		if(WeaponTemplate == None) continue;

		ItemTemplateManager.FindDataTemplateAllDifficulties(WeaponTemplate.DataName, DataTemplates);

		foreach DataTemplates(DataTemplate)
		{
			WeaponTemplate = X2WeaponTemplate(DataTemplate);
			if(WeaponTemplate == None) continue;
			RemoveWeaponSpread(WeaponTemplate);
		}
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

private function ApplyAmmoEffectsBasedOnHitChance()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2AmmoTemplate AmmoTemplate;
	local X2DataTemplate DataTemplate;
	local array<X2DataTemplate> DataTemplates;

	`Log("");
	`Log("<ReliableDamage.ApplyAmmoEffectsBasedOnHitChance>");

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	if (ItemTemplateManager == none) return;

	foreach ItemTemplateManager.IterateTemplates(DataTemplate)
	{
		AmmoTemplate = X2AmmoTemplate(DataTemplate);
		if(AmmoTemplate == None) continue;

		ItemTemplateManager.FindDataTemplateAllDifficulties(AmmoTemplate.DataName, DataTemplates);

		foreach DataTemplates(DataTemplate)
		{
			AmmoTemplate = X2AmmoTemplate(DataTemplate);
			if(AmmoTemplate == None) continue;

			AdjustAmmoTemplate(AmmoTemplate);
		}
	}

	`Log("</ReliableDamage.ApplyAmmoEffectsBasedOnHitChance>");
}

private function AdjustAmmoTemplate(X2AmmoTemplate AmmoTemplate)
{
	local X2Effect TargetEffect;

	foreach AmmoTemplate.TargetEffects(TargetEffect)
	{
		if(TargetEffect.ApplyChance > 0 || TargetEffect.ApplyChanceFn != None)
		{
			continue;
		}

		`Log("Adjusting" @ (AmmoTemplate.HasDisplayData() ? AmmoTemplate.GetItemFriendlyName() : string(AmmoTemplate.Name)) $ "." $ TargetEffect);
		TargetEffect.ApplyChanceFn = ApplyAmmoChance;
	}
}

private function name ApplyAmmoChance(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	local XComGameState_Ability Ability;

	Ability = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
	if(Ability != None && Ability.GetMyTemplate().AbilityToHitCalc.IsA('X2AbilityToHitCalc_StandardAim_RD'))
	{
		// Roll for success based on original HitChance.
		return `SYNC_RAND(100) < ApplyEffectParameters.AbilityResultContext.CalculatedHitChance
			? 'AA_Success'
			: 'AA_EffectChanceFailed';
	}

	// Default is success, without this ApplyChanceFn the game always applies all effects.
	return 'AA_Success';
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

defaultproperties
{
	Begin Object Class=Configuration Name=Configuration
	End Object
	Configuration=Configuration
}