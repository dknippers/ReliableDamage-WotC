class X2Condition_Toggle_RD extends X2Condition;

var const name FAILURE;
var const name SUCCESS;

// Determines the outcome of this condition
var bool Succeed;

event name CallMeetsCondition(XComGameState_BaseObject kTarget) { return GetResult(); }
event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource) { return GetResult(); }
event name CallAbilityMeetsCondition(XComGameState_Ability kAbility, XComGameState_BaseObject kTarget) { return GetResult(); }

private function name GetResult() { return Succeed ? SUCCESS : FAILURE; }

DefaultProperties
{
	Succeed = false
	FAILURE = "AA_Failure"
	SUCCESS = "AA_Success"
}
