class UITacticalHUD_RD extends UITacticalHUD;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName) {
	super.InitScreen(InitController, InitMovie, InitName);

	// Shot information panel
	m_kShotHUD = Spawn(class'UITacticalHUD_ShotHUD_RD', self).InitShotHUD();
}
