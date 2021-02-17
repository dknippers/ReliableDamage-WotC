class X2Condition_AlwaysFail_RD extends X2Condition;

event name CallMeetsCondition(XComGameState_BaseObject kTarget) { return 'AA_Failure'; }
event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource) { return 'AA_Failure'; }
event name CallAbilityMeetsCondition(XComGameState_Ability kAbility, XComGameState_BaseObject kTarget) { return 'AA_Failure'; }
