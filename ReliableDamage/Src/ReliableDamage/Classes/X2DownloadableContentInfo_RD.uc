class X2DownloadableContentInfo_RD extends X2DownloadableContentInfo;

static event OnPostTemplatesCreated()
{
	local Main Main;
	Main = new class'Main';

	Main.InitReliableDamage();
}
