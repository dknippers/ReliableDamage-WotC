// Condition for which the outcome can be altered at will
// by modifying the Succeed property
class X2Condition_Toggle_RD extends X2Condition;

// Determines the outcome of this condition
var bool Succeed;

event name CallMeetsCondition(XComGameState_BaseObject kTarget) { return InternalMeetsCondition(); }
event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource) { return InternalMeetsCondition(); }
event name CallAbilityMeetsCondition(XComGameState_Ability kAbility, XComGameState_BaseObject kTarget) { return InternalMeetsCondition(); }

private function name InternalMeetsCondition() { return Succeed ? 'AA_Success' : 'AA_Failure'; }
