class X2TargetingMethod_OverTheShoulder_RD extends X2TargetingMethod_OverTheShoulder;

// This raises an None-exception in Debug a lot,
// so I use this in Debug mode to fix that error
function bool GetCurrentTargetFocus(out Vector Focus)
{
	if(FiringUnit != None && FiringUnit.TargetingCamera != None)
	{
		Focus = FiringUnit.TargetingCamera.GetTargetLocation();
	}
	
	return true;
}