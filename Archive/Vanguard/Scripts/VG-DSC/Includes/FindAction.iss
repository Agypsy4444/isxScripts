;;;;;;;;;;
;;
;; FindAction - Designed for a Desciple
;;
;; The following identifies what we will be doing and sets the
;; variable "Action" to the name of what we want to execute.  Calling
;; this routine exucutes nothing while its sole purpose here is to identify
;; what we want to do and set the variable to be used in a different routine.
;; One example of using the variable "Action" is by using the Switch command, and
;; another example is to treat it like a subroutine.

variable string Action = "Idle"
variable bool Initialized = FALSE
variable bool hasScepterOfTheForgotten = FALSE
variable string RacialAbility = "Racial Ability: Spirit of Jin"


atom(script) FindAction()
{
	;;;;;;;;;;
	;; Set everything up
	if !${Initialized}
	{
		Action:Set[Initialize]
		return
	}

	;;;;;;;;;;
	;; check to see if we are dead
	if ${Me.HealthPct} <= 0 || ${GV[bool,DeathReleasePopup]}
	{
		Action:Set[WeAreDead]
		return
	}

	;;;;;;;;;;	
	;; if we are feign death then get out of it
	if ${Me.Effect[${FeignDeath}](exists)} && !${isPaused}
	{
		Action:Set[FeignDeath]
		return
	}

	;;;;;;;;;;	
	;; if we are feign death then get out of it
	if ${Me.Effect[${Meditate}](exists)} && !${isPaused}
	{
		Action:Set[Meditating]
		return
	}

	;;;;;;;;;;
	;; Server reset
	if ${doServerShutdown} && !${Me.InCombat} && !${Me.Target(exists)} && ${Me.Encounter}==0
	{
		Action:Set[CampOut]
		return
	}

	;;;;;;;;;;
	;; We just died so let's camp if we set the option to do so
	if ${doJustDied} && ${doCamp}
	{
		Action:Set[CampOut]
		return
	}
	
	;;;;;;;;;;
	;; we must have chunked so reload our settings
	if !${CurrentChunk.Equal[${Me.Chunk}]}
	{
		Action:Set[WeChunked]
		return
	}
	
	;;;;;;;;
	;; we can't do anything if we are stunned
	if ${Me.ToPawn.IsStunned}
	{
		Action:Set[WeAreStunned]
		return
	}

	;;;;;;;;
	;; we can't do anything if we are on a mount
	if ${Me.ToPawn.IsMounted}
	{
		Action:Set[WeAreMounted]
		return
	}

	;;;;;;;;;;
	;; In theory, changing forms should work great if there are no cooldowns
	;; but if there is then the script will appear to pause when your health
	;; bounces above and below 60% while it waits to change forms
	;; It is important to change forms now than later
	if ${Math.Calc[${Math.Calc[${Script.RunningTime}-${NextFormCheck}]}/1000]}>8
	{
		if ${Me.HealthPct}>=${ChangeFormPct} && !${Me.CurrentForm.Name.Equal[Celestial Tiger]} && ${Me.CurrentForm.Name.Equal[Celestial Tiger](exists)}
		{
			;; DPS - Inner Light is more effective
			Action:Set[Form_CelestialTiger]
			NextFormCheck:Set[${Script.RunningTime}]
			return
		}
		if ${Me.HealthPct}<${ChangeFormPct} && !${Me.CurrentForm.Name.Equal[Immortal Jade Dragon]} && ${Me.CurrentForm.Name.Equal[Immortal Jade Dragon](exists)}
		{
			;; HEALING - Blessed Wind and Kiss of Heaven are instant
			Action:Set[Form_ImmortalJadeDragon]
			NextFormCheck:Set[${Script.RunningTime}]
			return
		}
	}

	;;;;;;;;;;
	;; We want to ensure we have Inner Light, Resilient Grasshopper,
	;; and Aura of Rulers buffs are up at all times.  Mobs that stip buffs
	;; can have a detrimental affect of draining your energy because
	;; you will be constantly casting the buff
	if ${Me.CurrentForm.Name.Equal[Celestial Tiger]} && ${Me.Ability[${InnerLight}].JinCost}<=${Me.Stat[Adventuring,Jin]}
	{
		;; one of these are the correct Modified check
		if ${Me.Ability[${InnerLight}](exists)} && !${Me.Effect[${InnerLight}](exists)} && !${Me.Effect[${InnerLight}(Modified)](exists)} && !${Me.Effect[${InnerLight} (Modified)](exists)}
		{
			Action:Set[Buff_InnerLight]
			return
		}
	}
	if ${Me.Ability[${ResilientGrasshopper}](exists)} && !${Me.Effect[${ResilientGrasshopper}](exists)}
	{
		Action:Set[Buff_ResilientGrasshopper]
		return
	}
	if !${Me.Effect[Aura of Rulers](exists)} && ${Me.InCombat} && ${Me.Inventory[Scepter of the Forgotten].IsReady} && ${Me.Level}>=45
	{
		Action:Set[Buff_AuraOfRulers]
		return
	}

	;;;;;;;;;;
	;; Follow whomever you are following... it is a priority
	if !${Me.FName.Find[${Follow}]}
	{
		if ${Pawn[name,${Follow}](exists)}
		{
			if ${Pawn[name,${Follow}].Distance}>=5 && ${Pawn[name,${Follow}].Distance}<45
			{
				Action:Set[FollowPlayer]
				return
			}
		}
	}

	;;;;;;;;;;
	;; If we are not in combat and have a target then we will check to see if
	;; it is an AggroNPC.  If it is then go pull the target to us.  This is where
	;; we should feign death if we pulled too many AggroNPC's.
	if !${Me.InCombat}
	{
		call OkayToAttack
		if ${Return} && ${Me.Target(exists)} && !${Me.Target.IsDead} && ${Me.TargetHealth}>0
		{
			if (${doNPC} && ${Me.Target.Type.Equal[NPC]}) || (${doAggroNPC} && ${Me.Target.Type.Equal[AggroNPC]})
			{
				;; go get the target if we are hunting
				if ${doHunt}
				{
					doTankEndowementOfLife:Set[TRUE]
					Action:Set[PullTarget]
					return
				}

				;; attack the target only if it is in range and we are not hunting
				if !${doHunt}
				{
					if ${Me.Ability[${EnfeeblingShuriken}](exists)} && ${Me.Target.Distance}<=${Me.Ability[${EnfeeblingShuriken}].Range}
					{
						;echo 1111
						doTankEndowementOfLife:Set[TRUE]
						Action:Set[PullTarget]
						return
					}
					if ${Me.Ability[${RaJinFlare}](exists)} && ${Me.Target.Distance}<=${Me.Ability[${RaJinFlare}].Range}
					{
						;echo 2222
						doTankEndowementOfLife:Set[TRUE]
						Action:Set[PullTarget]
						return
					}
					if ${Me.Ability[${VoidHand}](exists)} && ${Me.Target.Distance}<=${Me.Ability[${VoidHand}].Range}
					{
						doTankEndowementOfLife:Set[TRUE]
						Action:Set[PullTarget]
						return
					}
				}
			}
		}
	}

	;;;;;;;;;;
	;; Immediately loot the corpse if it is within looting distance.  If it
	;; is outside looting range then the Idle routine will manage looting
	if ${doLoot} && ${Me.Target(exists)} && ${Me.Target.IsDead} && ${Me.Target.Distance}<5
	{
		Action:Set[LootCorpse]
		return
	}

	;;;;;;;;;;
	;; We need to ensure that we always assist the tank or change target
	;; to the first encounter if we are not fighting or do not have a target.
	;; Sometimes, tanks die and do not release so there's a chance we do not
	;; pickup the encounter unless we get hit.
	if !${Me.Target(exists)} || (${Me.Target(exists)} && ${Me.Target.IsDead})
	{
		;; get our health up if we are not in combat or target is dead
		if ${Me.DTarget(exists)} && ${Me.DTargetHealth}>0 && ${Me.DTargetHealth}<${KissOfHeavenPct} && ${Me.Ability[${KissOfHeaven}](exists)} && !${Me.Effect[${KissOfHeaven}](exists)} && ${Me.Ability[${KissOfHeaven}].JinCost}<=${Me.Stat[Adventuring,Jin]}
		{
			Action:Set[KissOfHeaven]
			return
		}
		if ${Me.HealthPct}>0 && ${Me.HealthPct}<${KissOfHeavenPct} && ${Me.Ability[${KissOfHeaven}](exists)} && !${Me.Effect[${KissOfHeaven}](exists)} && ${Me.Ability[${KissOfHeaven}].JinCost}<=${Me.Stat[Adventuring,Jin]}
		{
			Action:Set[KissOfHeaven]
			return
		}


		;; Assist the tank as long as it isn't me
		if ${Pawn[Name,${Tank}](exists)} && !${Tank.Find[${Me.FName}]}
		{
			if ${Pawn[Name,${Tank}].CombatState}>0 && ${Pawn[Name,${Tank}].Distance}<=50
			{
				Action:Set[AssistTank]
				return
			}
		}

		;; Grab an encounter
		if ${Me.Encounter}>0
		{
			Action:Set[TargetEncounter]
			return
		}
	}

	;;;;;;;;;;
	;; WE ARE IN COMBAT - everything we need to do to kill the target
	;; while healing self and tank
	if ${Me.InCombat}
	{
		;;;;;;;;;;
		;; I am trying to understand how a Disciple heals and from what I have observed
		;; is that whomever is set as your DTarget benefits from your melee heals.  Also,
		;; if we are in a group, our goal here is to keep the tank alive.  With that, I
		;; am going to experiment by setting the DTarget to either myself or the Tank
		;; based upon whom has the lowest health.
		if ${Me.IsGrouped}
		{
			for (i:Set[1] ; ${Group[${i}].ID(exists)} ; i:Inc)
			{
				if ${Tank.Find[${Group[${i}].Name}]} && ${Tank.Find[${Group[${i}].Distance}]}<25
				{
					if ${Group[${i}].Health}<${Me.HealthPct}
					{
						;; set DTarget to the Tank
						if !${Me.DTarget.Name.Equal[${Tank}]}
						{
							Pawn[exactname,${Tank}]:Target
						}
					}
					if ${Group[${i}].Health}>=${Me.HealthPct}
					{
						;; set DTarget to me
						if !${Me.DTarget.Name.Equal[${Me.FName}]}
						{
							Pawn[me]:Target
						}
					}
				}
			}
		}
		else
		{
			;; set DTarget to me
			if !${Me.DTarget.Name.Equal[${Me.FName}]}
			{
				Pawn[me]:Target
			}
		}

		;;;;;;;;;;
		;; Feign Death for 3 seconds if my health is below 20%, then heal self
		if ${Me.HealthPct}<${FeignDeathPct} || ${Me.Encounter}>=${FeignDeathEncounters}
		{
			echo * MyHealth=${Me.HealthPct}, FeignDeathPct=${FeignDeathPct}, Encounters=${Me.Encounter}, FeignDeathEncounters=${FeignDeathEncounters}
			if ${Me.Ability[${FeignDeath}](exists)} && ${Me.Ability[${FeignDeath}].TimeRemaining}==0
			{
				Action:Set[FeignDeath]
				return
			}
		}

		;;;;;;;;;;
		;; Use Racial Ability if our health is below 30%
		if ${Me.HealthPct}<${RacialAbilityPct}
		{
			if ${Me.Ability[${RacialAbility}](exists)} && ${Me.Ability[${RacialAbility}].IsReady}
			{
				Action:Set[RacialAbility]
				return
			}
		}

		;;;;;;;;;;
		;; Lao'Jin Flash for an instant heal without a cooldown when our health is below 50%, 15 second refresh
		if ${Me.DTarget(exists)} && ${Me.DTargetHealth}>0 && ${Me.DTargetHealth}<${LaoJinFlashPct}
		{
			if ${Me.Ability[${LaoJinFlash}](exists)} && ${Me.Ability[${LaoJinFlash}].IsReady} && ${Me.Ability[${LaoJinFlash}].JinCost}<=${Me.Stat[Adventuring,Jin]}
			{
				Action:Set[LaoJinFlash]
				return
			}
			if !${Me.Ability[${LaoJinFlash}](exists)} && ${Me.Ability[${LaoJinFlare}].IsReady} && ${Me.Ability[${LaoJinFlare}].JinCost}<=${Me.Stat[Adventuring,Jin]}
			{
				Action:Set[LaoJinFlare]
				return
			}
		}
		if ${Me.HealthPct}>0 && ${Me.HealthPct}<${LaoJinFlashPct}
		{
			if ${Me.Ability[${LaoJinFlash}](exists)} && ${Me.Ability[${LaoJinFlash}].IsReady} && ${Me.Ability[${LaoJinFlash}].JinCost}<=${Me.Stat[Adventuring,Jin]}
			{
				Pawn[me]:Target
				Action:Set[LaoJinFlash]
				return
			}
			if !${Me.Ability[${LaoJinFlash}](exists)} && ${Me.Ability[${LaoJinFlare}].IsReady} && ${Me.Ability[${LaoJinFlare}].JinCost}<=${Me.Stat[Adventuring,Jin]}
			{
				Pawn[me]:Target
				Action:Set[LaoJinFlare]
				return
			}
		}


		;;;;;;;;;;
		;; Breath of Life for a heal when our health is below 50%
		if ${Me.DTarget(exists)} && ${Me.DTargetHealth}>0 && ${Me.DTargetHealth}<${BreathOfLifePct}
		{
			;;;;;;;;;;
			;; Loa'Jin Flash/Flare are priority over other heals
			if ${Me.Ability[${LaoJinFlash}](exists)} && ${Me.Ability[${LaoJinFlash}].IsReady} && ${Me.Ability[${LaoJinFlash}].JinCost}<=${Me.Stat[Adventuring,Jin]}
			{
				Action:Set[LaoJinFlash]
				return
			}
			if !${Me.Ability[${LaoJinFlash}](exists)} && ${Me.Ability[${LaoJinFlare}].IsReady} && ${Me.Ability[${LaoJinFlare}].JinCost}<=${Me.Stat[Adventuring,Jin]}
			{
				Action:Set[LaoJinFlare]
				return
			}
			if (${Me.Ability[${LaoJinFlash}](exists)} && !${Me.Ability[${LaoJinFlash}].IsReady}) || (${Me.Ability[${LaoJinFlare}](exists)} && !${Me.Ability[${LaoJinFlare}].IsReady})
			{
				if ${Me.Ability[${BreathOfLife}](exists)} && ${Me.Ability[${BreathOfLife}].IsReady} && ${Me.Ability[${BreathOfLife}].JinCost}<=${Me.Stat[Adventuring,Jin]}
				{
					Action:Set[BreathOfLife]
					return
				}
				if !${Me.Ability[${BreathOfLife}](exists)} && ${Me.Ability[${BreathOfRenewal}].IsReady} && ${Me.Ability[${BreathOfRenewal}].JinCost}<=${Me.Stat[Adventuring,Jin]}
				{
					Action:Set[BreathOfRenewal]
					return
				}
			}
		}
		if ${Me.HealthPct}>0 && ${Me.HealthPct}<${BreathOfLifePct}
		{
			;;;;;;;;;;
			;; Loa'Jin Flash/Flare are priority over other heals
			if ${Me.Ability[${LaoJinFlash}](exists)} && ${Me.Ability[${LaoJinFlash}].IsReady} && ${Me.Ability[${LaoJinFlash}].JinCost}<=${Me.Stat[Adventuring,Jin]}
			{
				Pawn[me]:Target
				Action:Set[LaoJinFlash]
				return
			}
			if !${Me.Ability[${LaoJinFlash}](exists)} && ${Me.Ability[${LaoJinFlare}].IsReady} && ${Me.Ability[${LaoJinFlare}].JinCost}<=${Me.Stat[Adventuring,Jin]}
			{
				Pawn[me]:Target
				Action:Set[LaoJinFlare]
				return
			}
			if (${Me.Ability[${LaoJinFlash}](exists)} && !${Me.Ability[${LaoJinFlash}].IsReady}) || (${Me.Ability[${LaoJinFlare}](exists)} && !${Me.Ability[${LaoJinFlare}].IsReady})
			{
				if ${Me.Ability[${BreathOfLife}](exists)} && ${Me.Ability[${BreathOfLife}].IsReady} && ${Me.Ability[${BreathOfLife}].JinCost}<=${Me.Stat[Adventuring,Jin]}
				{
					Pawn[me]:Target
					Action:Set[BreathOfLife]
					return
				}
				if !${Me.Ability[${BreathOfLife}](exists)} && ${Me.Ability[${BreathOfRenewal}].IsReady} && ${Me.Ability[${BreathOfRenewal}].JinCost}<=${Me.Stat[Adventuring,Jin]}
				{
					Pawn[me]:Target
					Action:Set[BreathOfRenewal]
					return
				}
			}
		}

		;;;;;;;;;;
		;; Kiss of Heaven for an instant HOT when our health is below 60%, lasts 32 second
		if ${Me.DTarget(exists)} && ${Me.DTargetHealth}>0 && ${Me.DTargetHealth}<${KissOfHeavenPct}
		{
			if ${Me.Ability[${KissOfHeaven}](exists)} && ${Me.Ability[${KissOfHeaven}].IsReady} && !${Me.Effect[${KissOfHeaven}](exists)} && ${Me.Ability[${KissOfHeaven}].JinCost}<=${Me.Stat[Adventuring,Jin]}
			{
				Action:Set[KissOfHeaven]
				return
			}
		}
		if ${Me.HealthPct}>0 && ${Me.HealthPct}<${KissOfHeavenPct}
		{
			if ${Me.Ability[${KissOfHeaven}](exists)} && ${Me.Ability[${KissOfHeaven}].IsReady} && !${Me.Effect[${KissOfHeaven}](exists)} && ${Me.Ability[${KissOfHeaven}].JinCost}<=${Me.Stat[Adventuring,Jin]}
			{
				Pawn[me]:Target
				Action:Set[KissOfHeaven]
				return
			}
		}
		

		;;;;;;;;;;
		;; Lao'Jin Flash for an instant heal without a cooldown when our health is below 50%, 15 second refresh
		if ${Me.DTarget(exists)} && ${Me.DTargetHealth}>0 && ${Me.DTargetHealth}<${LaoJinFlashPct}
		{
			if ${Me.Ability[${LaoJinFlash}](exists)} && ${Me.Ability[${LaoJinFlash}].IsReady} && ${Me.Ability[${LaoJinFlash}].JinCost}<=${Me.Stat[Adventuring,Jin]}
			{
				Action:Set[LaoJinFlash]
				return
			}
			if !${Me.Ability[${LaoJinFlash}](exists)} && ${Me.Ability[${LaoJinFlare}].IsReady} && ${Me.Ability[${LaoJinFlare}].JinCost}<=${Me.Stat[Adventuring,Jin]}
			{
				Action:Set[LaoJinFlare]
				return
			}
		}
		if ${Me.HealthPct}>0 && ${Me.HealthPct}<${LaoJinFlashPct}
		{
			if ${Me.Ability[${LaoJinFlash}](exists)} && ${Me.Ability[${LaoJinFlash}].IsReady} && ${Me.Ability[${LaoJinFlash}].JinCost}<=${Me.Stat[Adventuring,Jin]}
			{
				Pawn[me]:Target
				Action:Set[LaoJinFlash]
				return
			}
			if !${Me.Ability[${LaoJinFlash}](exists)} && ${Me.Ability[${LaoJinFlare}].IsReady} && ${Me.Ability[${LaoJinFlare}].JinCost}<=${Me.Stat[Adventuring,Jin]}
			{
				Pawn[me]:Target
				Action:Set[LaoJinFlare]
				return
			}
		}

		;;;;;;;;;;
		;; stay within melee distance
		if ${Me.Target.Distance}<1 || ${Me.Target.Distance}>=5
		{
			if ${Me.Target.Distance}<=15 && ${doHunt}
			{
				Action:Set[MoveToMeleeDistance]
				return
			}
		}

		;;;;;;;;;;
		;; The following are our DPS/DAMAGE routines
		call OkayToAttack
		if ${Return}
		{
			;;;;;;;;;;
			;; these will add Jin if we get too low
			if ${Me.Stat[Adventuring,Jin]}<=13
			{
				if !${Me.Effect[${SuperiorSunFist}](exists)} && ${Me.Ability[${SuperiorSunFist}].TriggeredCountdown} && ${Me.Ability[${SuperiorSunFist}].TimeRemaining}==0
				{
					;echo SuperiorSunFist Ability=${Me.Ability[${SuperiorSunFist}](exists)}, Exist=${Me.Effect[${SuperiorSunFist}](exists)}, TimeRemaining=${Me.Ability[${SuperiorSunFist}].TimeRemaining}
					if ${Me.Target.Distance}<=${Me.Ability[${SuperiorSunFist}].Range}
					{
						Action:Set[Crit_SunFist]
						return
					}
				}
				if ${Me.Stat[Adventuring,Jin]}<=10 && !${Me.Effect[${SunFist}](exists)} && ${Me.Ability[${SunFist}].TriggeredCountdown} && ${Me.Ability[${SunFist}].TimeRemaining}==0
				{
					;echo SunFist Ability=${Me.Ability[${SunFist}](exists)}, Exist=${Me.Effect[${SunFist}](exists)}, TimeRemaining=${Me.Ability[${SunFist}].TimeRemaining}
					if ${Me.Target.Distance}<=${Me.Ability[${SunFist}].Range}
					{
						Action:Set[Crit_SunFist]
						return
					}
				}
			}

			;;;;;;;;;;
			;; Big Crit Heal Chain if our health is below 40%, 1 minute cooldown
			if ${Me.DTargetHealth}>0 && ${Me.DTargetHealth}<${Crit_HealPct} && ${Me.Target(exists)} && !${Me.Target.IsDead}
			{
				if ${Me.Ability[${ConcordantSplendor}](exists)} && ${Me.Ability[${ConcordantSplendor}].TriggeredCountdown} && ${Me.Ability[${ConcordantSplendor}].TimeRemaining}==0
				{
					if ${Me.Target.Distance}<=${Me.Ability[${ConcordantSplendor}].Range}
					{
						Action:Set[Crit_HealSeries]
						return
					}
				}
				if ${Me.Ability[${ConcordantPalm}](exists)} && ${Me.Ability[${ConcordantPalm}].TriggeredCountdown} && ${Me.Ability[${ConcordantPalm}].TimeRemaining}==0
				{
					if ${Me.Target.Distance}<=${Me.Ability[${ConcordantPalm}].Range}
					{
						Action:Set[Crit_HealSeries]
						return
					}
				}
				if ${Me.Ability[${ConcordantHand}](exists)} && ${Me.Ability[${ConcordantHand}].TriggeredCountdown} && ${Me.Ability[${ConcordantHand}].TimeRemaining}==0
				{
					if ${Me.Target.Distance}<=${Me.Ability[${ConcordantHand}].Range}
					{
						Action:Set[Crit_HealSeries]
						return
					}
				}
				if ${Me.Target.Distance}<=5
				{
					Action:Set[BuildCrit]
					return
				}
			}
			if ${Me.HealthPct}>0 && ${Me.HealthPct}<${Crit_HealPct} && ${Me.Target(exists)} && !${Me.Target.IsDead}
			{
				if ${Me.Ability[${ConcordantSplendor}](exists)} && ${Me.Ability[${ConcordantSplendor}].TriggeredCountdown} && ${Me.Ability[${ConcordantSplendor}].TimeRemaining}==0
				{
					if ${Me.Target.Distance}<=${Me.Ability[${ConcordantSplendor}].Range}
					{
						Pawn[me]:Target
						Action:Set[Crit_HealSeries]
						return
					}
				}
				if ${Me.Ability[${ConcordantPalm}](exists)} && ${Me.Ability[${ConcordantPalm}].TriggeredCountdown} && ${Me.Ability[${ConcordantPalm}].TimeRemaining}==0
				{
					if ${Me.Target.Distance}<=${Me.Ability[${ConcordantPalm}].Range}
					{
						Action:Set[Crit_HealSeries]
						return
					}
				}
				if ${Me.Ability[${ConcordantHand}](exists)} && ${Me.Ability[${ConcordantHand}].TriggeredCountdown} && ${Me.Ability[${ConcordantHand}].TimeRemaining}==0
				{
					if ${Me.Target.Distance}<=${Me.Ability[${ConcordantHand}].Range}
					{
						Action:Set[Crit_HealSeries]
						return
					}
				}
				if ${Me.Target.Distance}<=5
				{
					Action:Set[BuildCrit]
					return
				}
			}

			;;;;;;;;;;
			;; Get our endurance leaching buff up so that we can have more
			;; endurance during the fight
			if ${Me.Target(exists)} && !${Me.Target.IsDead} && ${Me.Ability[${LeechsGrasp}](exists)} && ${Me.Ability[${LeechsGrasp}].JinCost}<=${Me.Stat[Adventuring,Jin]}
			{
				if !${Me.Effect[${LeechsGrasp}](exists)} && !${Me.Effect[${LeechsGrasp}(Modified)](exists)} && !${Me.Effect[${LeechsGrasp} (Modified)](exists)}
				{
					if ${Me.Target.Distance}<=${Me.Ability[${LeechsGrasp}].Range}
					{
						Action:Set[LeechsGrasp]
						return
					}
				}
			}

			;;;;;;;;;;
			;; Start woking on our Falling Petal and White Lotus Crit Buff line:
			;; within 10m it increases damage and healing for 5 minutes
			variable bool PetalsAreUp = TRUE
			if  ${Me.Ability[${FallingPetal}](exists)} && !${Me.Ability[${PetalSplitsEarth}](exists)}
			{
				if (!${Me.Effect[${FallingPetal}](exists)} || ${Me.Effect[${FallingPetal}].TimeRemaining}<60)
				{
					PetalsAreUp:Set[FALSE]
					if ${Me.Ability[${FallingPetal}].TriggeredCountdown} && ${Me.Target.Distance}<=${Me.Ability[${FallingPetal}].Range}
					{
						ExecutedAbility:Set[${FallingPetal}]
						Action:Set[Crit_PetalSeries]
						return
					}
				}
			}
			if ${Me.Ability[${PetalSplitsEarth}](exists)}
			{
				if (!${Me.Effect[${PetalSplitsEarth}](exists)} || ${Me.Effect[${PetalSplitsEarth}].TimeRemaining}<60)
				{
					PetalsAreUp:Set[FALSE]
					if ${Me.Ability[${PetalSplitsEarth}].TriggeredCountdown} && ${Me.Target.Distance}<=${Me.Ability[${PetalSplitsEarth}].Range}
					{
						ExecutedAbility:Set[${PetalSplitsEarth}]
						Action:Set[Crit_PetalSeries]
						return
					}
				}
			}
			if ${Me.Ability[${WhiteLotusStrike}](exists)}
			{
				if (!${Me.Effect[${WhiteLotusStrike}](exists)} || ${Me.Effect[${WhiteLotusStrike}].TimeRemaining}<60)
				{
					PetalsAreUp:Set[FALSE]
					if ${Me.Ability[${WhiteLotusStrike}].TriggeredCountdown} && ${Me.Target.Distance}<=${Me.Ability[${WhiteLotusStrike}].Range}
					{
						ExecutedAbility:Set[${WhiteLotusStrike}]
						Action:Set[Crit_PetalSeries]
						return
					}
				}
			}

			;;;;;;;;;;
			;; Start woking on our Endowments:
			;; Master = reduces 10% energy and endurance costs to all within 10m
			;; Emnity = increase 10% damage for self
			;; Life = increase DTarget's health and regenerates our jin
			variable bool EndowementsAreUp = FALSE
			if ${Me.Ability["Endowment of Mastery"](exists)} && ${Me.Effect["Endowment of Mastery"].TimeRemaining}>=45
			{
				if ${Me.Ability["Endowment of Enmity"](exists)} && ${Me.Effect["Endowment of Enmity"].TimeRemaining}>=45
				{
					if ${Me.Ability["Endowment of Life"](exists)} && ${Me.Effect["Endowment of Life"].TimeRemaining}>=45
					{
						EndowementsAreUp:Set[TRUE]
					}
				}
			}
			if !${EndowementsAreUp}
			{
				if ${Me.Ability["Endowment of Mastery"](exists)} && (!${Me.Effect["Endowment of Mastery"](exists)} || ${Me.Effect["Endowment of Mastery"].TimeRemaining}<45)
				{
					if ${Me.Ability[${SoulCutter}].IsReady} && ${Me.Ability[${VoidHand}].IsReady} && ${Me.Ability[${KnifeHand}].IsReady} && ${Me.Target.Distance}<=5
					{
						Action:Set[Endowment_Mastery]
						return
					}
				}
				if ${Me.Ability["Endowment of Enmity"](exists)} && (!${Me.Effect["Endowment of Enmity"](exists)} || ${Me.Effect["Endowment of Enmity"].TimeRemaining}<45) && ${Me.Ability[${RaJinFlare}].JinCost}<=${Me.Stat[Adventuring,Jin]}
				{
					if (${Me.Ability[${CycloneKick}].IsReady} && ${Me.Target.Distance}<=5) && ${Me.Ability[${RaJinFlare}].IsReady}
					{
						if ${doRangedWeapon}
						{
							Action:Set[Endowment_Enmity]
							return
						}
						elseif !${doRangedWeapon} && ${Me.Target.Distance}<=5
						{
							Action:Set[Endowment_Enmity]
							return
						}
					}
				}
				if ${Me.Ability["Endowment of Life"](exists)} && (!${Me.Effect["Endowment of Life"](exists)} || ${Me.Effect["Endowment of Life"].TimeRemaining}<45) && ${Me.Stat[Adventuring,Jin]}>=2
				{
					if ${Me.Ability[${BlessedWind}].IsReady} && ${Me.Ability[${CycloneKick}].IsReady} && ${Me.Ability[${VoidHand}].IsReady} && ${Me.Target.Distance}<=5
					{
						Action:Set[Endowment_Life]
						return
					}
				}
			}
			
			;;;;;;;;;;
			;; Do we need this?  Not really, but could make a difference down the road
			if ${Me.Stat[Adventuring,Jin]}>=10 
			{
				if ${Me.Ability[${BloomingRidgeHand}](exists)} && ${Me.Ability[${BloomingRidgeHand}].IsReady} && !${Me.TargetMyDebuff[${BloomingRidgeHand}](exists)}
				{
					;Action:Set[BloomingRidgeHand]
					;return
				}
				if ${Me.Ability[${KissOfTorment}](exists)} && ${Me.Stat[Adventuring,Jin]}>12 && !${Me.Effect[${KissOfTorment}](exists)} && ${Me.Ability[${KissOfTorment}].TriggeredCountdown} && ${Me.Ability[${KissOfTorment}].TimeRemaining}==0
				{
					;Action:Set[Crit_KissOfTorment]
					;return
				}
			}

			;;;;;;;;;;
			;; This will replenish some energy
			if ${Me.EnergyPct}<=20 && ${Me.Ability[${MindlessClutch}](exists)} && ${Me.Ability[${MindlessClutch}].IsReady} && ${Me.Ability[${MindlessClutch}].JinCost}<=${Me.Stat[Adventuring,Jin]}
			{
				if !${Me.TargetMyDebuff[${MindlessClutch}](exists)} && !${Me.Effect[${MindlessClutch}](exists)}
				{
					if ${Me.Target.Distance}<=${Me.Ability[${MindlessClutch}].Range}
					{
						Action:Set[MindlessClutch]
						return
					}
				}
			}
			
			;;;;;;;;;;
			;; Build a crit real fast to increase our Jin
			if ${Me.Stat[Adventuring,Jin]}<=7 && ${Me.Ability[${Clarity}].TimeRemaining}==0 && ${Me.Target.Distance}<=5
			{
				Action:Set[BuildFastCrit]
				return
			}
			
			;;;;;;;;;;
			;; Use Ra'Jin Flare and turn Melee Attack Back On... Ranged Damage
			;if ${Me.Encounter}< && ${Me.Stat[Adventuring,Jin]}>8 && ${Me.HealthPct}>=${Crit_DPS_RaJinFlarePct} && ${Me.Ability[${RaJinFlare}].JinCost}<=${Me.Stat[Adventuring,Jin]}
			if ${EndowementsAreUp}
			{
				if ${Me.Stat[Adventuring,Jin]}>=8 && ${Me.HealthPct}>=${Crit_DPS_RaJinFlarePct} && ${doRangedWeapon} && !${Me.Effect[${Clarity}](exists)}
				{
					if ${Me.Ability[${RaJinFlare}](exists)} && ${Me.Ability[${RaJinFlare}].Range}>10 && ${Me.Ability[${RaJinFlare}].IsReady} && ${Me.Ability[${RaJinFlare}].JinCost}<=${Me.Stat[Adventuring,Jin]}
					{
						Action:Set[RaJinFlare]
						return
					}
					elseif ${Me.Ability[Ranged Attack].IsReady}
					{
						Action:Set[RangedAttack]
						return
					}
					return
				}

				;;;;;;;;;;
				;; These do some serious damage so execute these whenever possible!  It also builds jin
				if ${PetalsAreUp} && ${Me.Target.Distance}<=5
				{
					if ${Me.Ability[${FocusedSonicBlast}](exists)} && !${Me.Effect[${FocusedSonicBlast}](exists)} && ${Me.Ability[${FocusedSonicBlast}].TriggeredCountdown} && ${Me.Ability[${FocusedSonicBlast}].TimeRemaining}==0
					{
						Action:Set[Crit_DPS]
						return
					}
					if ${Me.Ability[${TouchOfDiscord}](exists)} && !${Me.Effect[${TouchOfDiscord}](exists)} && ${Me.Ability[${TouchOfDiscord}].TriggeredCountdown} && ${Me.Ability[${TouchOfDiscord}].TimeRemaining}==0
					{
						Action:Set[Crit_DPS]
						return
					}
					if ${Me.Ability[${GraspOfDiscord}](exists)} && !${Me.Effect[${GraspOfDiscord}](exists)} && ${Me.Ability[${GraspOfDiscord}].TriggeredCountdown} && ${Me.Ability[${GraspOfDiscord}].TimeRemaining}==0
					{
						Action:Set[Crit_DPS]
						return
					}
					if ${Me.Ability[${PalmOfDiscord}](exists)} && !${Me.Effect[${PalmOfDiscord}](exists)} && ${Me.Ability[${PalmOfDiscord}].TriggeredCountdown} && ${Me.Ability[${PalmOfDiscord}].TimeRemaining}==0
					{
						Action:Set[Crit_DPS]
						return
					}
					if ${Me.Ability[${FistOfDiscord}](exists)} && !${Me.Effect[${FistOfDiscord}](exists)} && ${Me.Ability[${FistOfDiscord}].TriggeredCountdown} && ${Me.Ability[${FistOfDiscord}].TimeRemaining}==0
					{
						Action:Set[Crit_DPS]
						return
					}
				}

				;;;;;;;;;;
				;; lets build out health and jin by repeating Endowement of Life
				if ${Me.Ability[${BlessedWind}](exists)} && ${Me.Ability[${CycloneKick}](exists)} && ${Me.Ability[${VoidHand}](exists)} && ${Me.Stat[Adventuring,Jin]}>=2
				{
					if ${Me.Ability[${BlessedWind}].IsReady} && ${Me.Ability[${CycloneKick}].IsReady} && ${Me.Ability[${VoidHand}].IsReady} && ${Me.Target.Distance}<=5
					{
						Action:Set[Endowment_Life]
						return
					}
				}
				
				;;;;;;;;;;
				;; Last ability to use... available at level 2
				if ${Me.Ability[${BlessedWind}](exists)}
				{
					if ${Me.Ability[${BlessedWind}].IsReady} && ${Me.Target.Distance}<=5
					{
						Action:Set[BlessedWind]
						return
					}
				}

				;;;;;;;;;;
				;; Last ability to use... available at level 1
				if ${Me.Ability[${VoidHand}](exists)} && ${Me.EndurancePct}>20
				{
					if ${Me.Ability[${VoidHand}].IsReady} && ${Me.Target.Distance}<=5
					{
						Action:Set[VoidHand]
						return
					}
				}
			}
		}
	}
}

