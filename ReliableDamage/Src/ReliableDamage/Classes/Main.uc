class Main extends Object config(ReliableDamage);

var config bool RemoveDamageSpread;

delegate WithEffect(X2Effect Effect);
delegate WithAbilityTemplate(X2AbilityTemplate AbilityTemplate);

function InitReliableDamage()
{
	if(RemoveDamageSpread)
	{
		RemoveDamageSpreadFromWeapons();
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

	// We only change abilities that use StandardAim
	StandardAim = X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc);
	if(StandardAim == None) return;

	// Only replace if it is not already replaced
	StandardAim_RD = X2AbilityToHitCalc_StandardAim_RD(AbilityTemplate.AbilityToHitCalc);
	if(StandardAim_RD != None) return;

	// Do not touch abilities that have any displacement effects.
	// Making those abilities hit 100% of the time is extremely imbalanced.
	if(HasDisplacementEffect(AbilityTemplate)) return;

	if(RemoveDamageSpread) RemoveDamageSpreadFromAbility(AbilityTemplate);

	if(ReplaceWeaponEffects(AbilityTemplate))
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

private function bool ReplaceWeaponEffects(X2AbilityTemplate AbilityTemplate)
{
	local X2Effect TargetEffect;	
	local bool bMadeReplacements;

	// Replace both single target and multi target effects
	foreach AbilityTemplate.AbilityTargetEffects(TargetEffect)
	{
		if(ReplaceWeaponEffect(AbilityTemplate, TargetEffect, true))
		{
			bMadeReplacements = true;
		}
	}		

	foreach AbilityTemplate.AbilityMultiTargetEffects(TargetEffect)
	{
		if(ReplaceWeaponEffect(AbilityTemplate, TargetEffect, false))
		{
			bMadeReplacements = true;
		}
	}

	return bMadeReplacements;
}

private function bool ReplaceWeaponEffect(X2AbilityTemplate AbilityTemplate, X2Effect TargetEffect, bool bIsSingleTargetEffect)
{
	local X2Condition_Toggle_RD ToggleCondition;
	local X2Effect_ApplyWeaponDamage ApplyWeaponDamage;
	local X2Effect_ApplyWeaponDamage_RD ApplyWeaponDamage_RD;

	// Only look at Effects that work on hit and deal damage
	if(!TargetEffect.bApplyOnHit || !TargetEffect.bAppliesDamage) return false;

	ApplyWeaponDamage = X2Effect_ApplyWeaponDamage(TargetEffect);
	if(ApplyWeaponDamage == None) return false;

	ApplyWeaponDamage_RD = X2Effect_ApplyWeaponDamage_RD(TargetEffect);

	// Already replaced by us, ignore.
	if(ApplyWeaponDamage_RD != None) return false;

	ApplyWeaponDamage_RD = new class'X2Effect_ApplyWeaponDamage_RD';
	ApplyWeaponDamage_RD.Clone(ApplyWeaponDamage);

	// Disable the original ApplyWeaponDamage effect by adding a condition we can
	// switch on or off at will. We cannot remove it from the Effects as it is readonly.
	ToggleCondition = new class'X2Condition_Toggle_RD';
	ToggleCondition.Succeed = false;

	// Disable the original damage effect
	ApplyWeaponDamage.TargetConditions.AddItem(ToggleCondition);
	ApplyWeaponDamage.bAppliesDamage = false;
	ApplyWeaponDamage.bApplyOnHit = false;

	if(bIsSingleTargetEffect)
	{
		AbilityTemplate.AddTargetEffect(ApplyWeaponDamage_RD);
	}
	else 
	{
		AbilityTemplate.AddMultiTargetEffect(ApplyWeaponDamage_RD);
	}

	`Log(AbilityTemplate.DataName $ "." $ ApplyWeaponDamage.Class);

	return true;
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
