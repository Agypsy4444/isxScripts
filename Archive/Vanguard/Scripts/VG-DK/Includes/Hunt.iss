/*
Hunt v1.0
by:  Zandros, 27 Jan 2009

Description:
Returns TRUE or FALSE after finding and moving to mob

parameters:  None

Example Code:
call Hunt
if ${Return}
"found a mob and moved within attack range"

External Routines that must be in your program:  FindTarget, MoveCloser

Variables to use in your program:
variable string Status				"Use this in your routines to echo what is happening"
*/

/* Toggle this on or off in your scripts */
;variable bool isHuntReady = TRUE
;variable bool doHunt = FALSE
;variable int MobMinLevel = ${Me.Level}
;variable int MobMaxLevel = ${Me.Level}
;variable int ConCheck = 2
;variable int Distance = 50

;===================================================
;===              Hunt Routine                  ====
;===================================================
function:bool Hunt()
{
	;-------------------------------------------
	; Clear our target if we can't see it
	;-------------------------------------------
	if ${doHunt} && ${Me.Target(exists)} && !${Me.Target.HaveLineOfSightTo}
	{
		;; clear our target
		VGExecute "/cleartargets"
		wait 5 !${Me.Target(exists)}
	}

	;-------------------------------------------
	; Return if we don't want to hunt
	;-------------------------------------------
	if !${doHunt} || ${Me.InCombat} || ${Me.HealthPct}<80 || ${Me.EnergyPct}<80 || ${Me.EndurancePct}<80 || ${Me.Target(exists)}
		return FALSE

	;-------------------------------------------
	; Find a Mob (AggroNPC)
	;-------------------------------------------
	if !${Me.Target(exists)}
		call FindTarget AggroNPC ${Distance} ${ConCheck} ${MobMinLevel} ${MobMaxLevel}
		
	;-------------------------------------------
	; Find a Mob (NPC)
	;-------------------------------------------
	if !${Me.Target(exists)}
		call FindTarget NPC ${Distance} ${ConCheck} ${MobMinLevel} ${MobMaxLevel}

	;-------------------------------------------
	; Must pass our 1st check
	;-------------------------------------------
	if !${Me.Target(exists)}
		return FALSE

	;-------------------------------------------
	; Must pass our 2nd check
	;-------------------------------------------
	if ${Me.Target.Owner(exists)} && !${Me.Target.OwnedByMe} && !${Me.Target.Type.Equal[Corpse]}
	return FALSE

	if ${Me.Target(exists)}
	{
		call FaceTarget
	}

	;-------------------------------------------
	; Move closer to target (15m) - This ain't good if we get stuck
	;-------------------------------------------
	variable int i = 0
	if ${doRanged} && ${doMove} && ${Me.Target(exists)} && !${Me.InCombat} && !${isPaused} && ${Me.Encounter}==0
	{
		CurrentAction:Set[Hunt - Moving closer (Ranged)]
		i:Set[${Me.Ability[Ranged Attack].Range}]
		if ${i}<15
		{
			;; maximum range to move to
			i:Set[14]
		}
		if ${i}>25
		{
			;; maximum range to move to
			i:Set[24]
		}
		i:Set[${Math.Calc[${i}-3]]
		call MoveCloser ${Me.Target.X} ${Me.Target.Y} ${i}
		if !${Return}
		{
			;; clear target
			CurrentAction:Set[Clearing Targets]
			VGExecute "/cleartargets"
			wait 10
			return FALSE
		}
	}
	if !${doRanged} && ${doMove} && ${Me.Target(exists)} && !${Me.InCombat} && !${isPaused} && ${Me.Encounter}==0
	{
		CurrentAction:Set[Hunt - Moving closer (Melee)]
		call MoveCloser ${Me.Target.X} ${Me.Target.Y} 4
		if !${Return}
		{
			;; clear target
			CurrentAction:Set[Clearing Targets]
			VGExecute "/cleartargets"
			wait 10
			return FALSE
		}
	}

	;-------------------------------------------
	; Oops, target is a corpse
	;-------------------------------------------
	if ${Me.Target(exists)} && ${Me.Target.Type.Equal[Corpse]}
		return FALSE
		
	if ${Me.Target(exists)}
	{
		if !${Me.Target.HaveLineOfSightTo}
		{
			;; clear target
			CurrentAction:Set[Clearing Targets]
			VGExecute "/cleartargets"
			wait 10
			return FALSE
		}
		call FaceTarget
	}
		

	;-------------------------------------------
	; Successfully found a target and moved into attack range
	;-------------------------------------------
	if ${Me.Target(exists)}
	{
		EchoIt "Hunt: Found (${Me.Target.Name}) and moved to within ${Me.Target.Distance} meters"
		call FaceTarget
		return TRUE
	}
	return FALSE
}

