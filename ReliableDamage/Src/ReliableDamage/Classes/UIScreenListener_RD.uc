class UIScreenListener_RD extends UIScreenListener;

// This event is triggered after a screen is initialized
event OnInit(UIScreen Screen)
{ 
	InitShotHUD(Screen);	
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
    ScreenClass = None
}