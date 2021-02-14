class UITacticalHUD_ShotHUD_RD extends UITacticalHUD_ShotHUD;

simulated function Update()
{
	super.Update();	
	SetDamageRangeMessage();
}

// Generates the message "X-Y" indicating the damage range
// We generate decimal numbers rather than integers to give 
// a better feeling of the damage being applied.
private function SetDamageRangeMessage()
{
	local int TargetIndex, AllowsShield;
	local StateObjectReference EmptyRef; 
	local XComGameState_Ability AbilityState;
	local X2AbilityTemplate AbilityTemplate;
	local AvailableTarget kTarget;	
	local UITacticalHUD TacticalHUD;
	local AvailableAction SelectedUIAction;
	local X2TargetingMethod TargetingMethod;
	local WeaponDamageValue MinDamage, MaxDamage;
	local X2AbilityToHitCalc_StandardAim_RD StandardAim_RD;

	local string sMinDamage, sMaxDamage, DamageText;

	// No valid action selected, we're done
	TacticalHUD = UITacticalHUD(Screen);
	SelectedUIAction = TacticalHUD.GetSelectedAction();
	if (SelectedUIAction.AbilityObjectRef.ObjectID == 0) return;
	
	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(SelectedUIAction.AbilityObjectRef.ObjectID));
	AbilityTemplate = AbilityState.GetMyTemplate();		

	// Ability without a AbilityToHitCalc, cannot be an ability we altered.
	if(AbilityTemplate.AbilityToHitCalc == None)
	{
		return;
	}

	StandardAim_RD = X2AbilityToHitCalc_StandardAim_RD(AbilityTemplate.AbilityToHitCalc);
	
	// We did not modify this template, never mind!
	if(StandardAim_RD == None)
	{
		return;
	}

	TargetingMethod = TacticalHUD.GetTargetingMethod();
	if( TargetingMethod != None )
	{
		TargetIndex = TargetingMethod.GetTargetIndex();
		if( SelectedUIAction.AvailableTargets.Length > 0 && TargetIndex < SelectedUIAction.AvailableTargets.Length )
			kTarget = SelectedUIAction.AvailableTargets[TargetIndex];
	}

	// In the rare case that this ability is self-targeting, but has a multi-target effect on units around it,
	// look at the damage preview, just not against the target (self).
	if(AbilityTemplate.AbilityTargetStyle.IsA('X2AbilityTarget_Self')
		&& AbilityTemplate.AbilityMultiTargetStyle != None 
		&& AbilityTemplate.AbilityMultiTargetEffects.Length > 0 )
	{
		AbilityState.GetDamagePreview(EmptyRef, MinDamage, MaxDamage, AllowsShield);
	}
	else
	{
		AbilityState.GetDamagePreview(kTarget.PrimaryTarget, MinDamage, MaxDamage, AllowsShield);
	}		

	// Round Min and Max damage to 2 decimal places
	// or display as whole integers if rounding is enabled
	if(StandardAim_RD.RoundingEnabled)
	{
		sMinDamage = string(Round(StandardAim_RD.MinDamage));
		sMaxDamage = string(Round(StandardAim_RD.MaxDamage));

		// Floats apparently always have 4 decimal places
		// Since we already made sure the last ones are 00 
		// we chop those off.
		DamageText = sMinDamage;

		if(sMinDamage != sMaxDamage)
		{
			DamageText $= "-" $ sMaxDamage;
		}
	} 
	else
	{
		// Without rounding to whole numbers
		// we display the actual damage rounded to 2 decimal places
		sMinDamage = string(int(StandardAim_RD.MinDamage * 100) / 100.0);
		sMaxDamage = string(int(StandardAim_RD.MaxDamage * 100) / 100.0);

		// Floats apparently always have 4 decimal places
		// Since we already made sure the last ones are 00 
		// we chop those off.
		DamageText = Left(sMinDamage, Len(sMinDamage) - 2);	

		if(StandardAim_RD.MinDamage != StandardAim_RD.MaxDamage)
		{
			DamageText $= "-" $ Left(sMaxDamage, Len(sMaxDamage) - 2);		
		}
	}	
		
	ResetDamageBreakdown();
	AddDamage(class'UIUtilities_Text'.static.GetColoredText(DamageText, eUIState_Good, 36), true);		
}