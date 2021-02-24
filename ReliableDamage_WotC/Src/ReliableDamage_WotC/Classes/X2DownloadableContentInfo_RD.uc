class X2DownloadableContentInfo_RD extends X2DownloadableContentInfo;

var const Main Main;

static event OnPostTemplatesCreated()
{
	default.Main.InitReliableDamage();
}

defaultproperties
{
	Begin Object Class=Main Name=Main
	End Object
	Main=Main
}