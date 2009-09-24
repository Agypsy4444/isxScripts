﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Diagnostics;
using System.Drawing;
using EQ2.ISXEQ2;
using InnerSpaceAPI;
using LavishVMAPI;
using System.IO;

namespace EQ2GlassCannon
{
	public partial class PlayerController
	{
		/************************************************************************************/
		protected void AppendActorInfo(FlexStringBuilder ThisBuilder, int iBulletNumber, Actor ThisActor)
		{
			ThisBuilder.AppendedLinePrefix = "   ";
			if (!ThisActor.IsValid)
			{
				ThisBuilder.AppendLine("{0}. Actor not valid.", iBulletNumber);
				return;
			}

			ThisBuilder.AppendLine("{0}. \"{1}\" ({2}) found {3:0.00} meters away at ({4:0.00}, {5:0.00}, {6:0.00})",
				iBulletNumber,
				ThisActor.Name,
				ThisActor.ID,
				ThisActor.Distance,
				ThisActor.X,
				ThisActor.Y,
				ThisActor.Z);
			ThisBuilder.AppendedLinePrefix = "      ";

			string strFullName = ThisActor.Name;
			if (!string.IsNullOrEmpty(ThisActor.LastName))
				strFullName += " " + ThisActor.LastName;
			if (!string.IsNullOrEmpty(ThisActor.SuffixTitle))
				strFullName += " " + ThisActor.SuffixTitle;
			if (!string.IsNullOrEmpty(ThisActor.Guild))
				strFullName += " <" + ThisActor.Guild + ">";

			ThisBuilder.AppendLine("Full Name: {0}", strFullName);

			ThisBuilder.AppendLine("Type: {0}", ThisActor.Type);
			ThisBuilder.AppendLine("Class: {0}", ThisActor.Class);
			ThisBuilder.AppendLine("Race: {0}", ThisActor.Race);
			ThisBuilder.AppendLine("Level(Effective): {0}({1})", ThisActor.Level, ThisActor.EffectiveLevel);
			ThisBuilder.AppendLine("Encounter Size: {0}", ThisActor.EncounterSize);
			ThisBuilder.AppendLine("Speed: {0}%", ThisActor.Speed);

			List<string> astrFlags = new List<string>();
			if (ThisActor.IsLinkdead)
				astrFlags.Add("IsLinkdead");

			if (ThisActor.IsSolo)
				astrFlags.Add("IsSolo");
			else if (ThisActor.IsHeroic)
				astrFlags.Add("IsHeroic");
			else if (ThisActor.IsEpic)
				astrFlags.Add("IsEpic");

			if (ThisActor.IsMerchant)
				astrFlags.Add("IsMerchant");
			if (ThisActor.IsBanker)
				astrFlags.Add("IsBanker");
			if (ThisActor.IsInvis)
				astrFlags.Add("IsInvis");
			if (ThisActor.IsStealthed)
				astrFlags.Add("IsStealthed");
			if (ThisActor.IsDead)
				astrFlags.Add("IsDead");
			if (ThisActor.IsFD)
				astrFlags.Add("IsFD");
			if (ThisActor.IsAggro)
				astrFlags.Add("IsAggro");
			if (ThisActor.IsLocked)
				astrFlags.Add("IsLocked");
			if (ThisActor.IsEncounterBroken)
				astrFlags.Add("IsEncounterBroken");
			if (ThisActor.IsNamed)
				astrFlags.Add("IsNamed");
			if (ThisActor.IsAPet)
				astrFlags.Add("IsAPet");
			if (ThisActor.IsMyPet)
				astrFlags.Add("IsMyPet");
			if (ThisActor.IsChest)
				astrFlags.Add("IsChest");

			if (ThisActor.IsIdle)
				astrFlags.Add("IsIdle");
			else if (ThisActor.IsBackingUp)
				astrFlags.Add("IsBackingUp");
			else if (ThisActor.IsStrafingLeft)
				astrFlags.Add("IsStrafingLeft");
			else if (ThisActor.IsStrafingRight)
				astrFlags.Add("IsStrafingRight");

			if (ThisActor.InCombatMode)
				astrFlags.Add("InCombatMode");
			else if (ThisActor.IsCrouching)
				astrFlags.Add("IsCrouching");
			else if (ThisActor.IsSitting)
				astrFlags.Add("IsSitting");

			if (ThisActor.IsSprinting)
				astrFlags.Add("IsSprinting");
			else if (ThisActor.IsWalking)
				astrFlags.Add("IsWalking");
			else if (ThisActor.IsRunning)
				astrFlags.Add("IsRunning");

			if (ThisActor.OnCarpet)
				astrFlags.Add("OnCarpet");
			else if (ThisActor.OnHorse)
				astrFlags.Add("OnHorse");
			else if (ThisActor.OnGriffin)
				astrFlags.Add("OnGriffin");
			else if (ThisActor.OnGriffon)
				astrFlags.Add("OnGriffon");

			string strFlags = string.Join(", ", astrFlags.ToArray());
			ThisBuilder.AppendLine("Flags: {0}", strFlags);
			return;
		}

		/************************************************************************************/
		public virtual bool OnCustomSlashCommand(string strCommand, string[] astrParameters)
		{
			string strCondensedParameters = string.Join(" ", astrParameters).Trim();

			switch (strCommand)
			{
				/// Directly acquire an offensive target.
				case "gc_attack":
				{
					Actor MyTargetActor = MeActor.Target();
					if (MyTargetActor.IsValid)
					{
						/// Don't bother filtering. Just grab the ID, let the other code determine if it's a legit target.
						m_iOffensiveTargetID = MyTargetActor.ID;
						Program.Log("Offensive target set to \"{0}\" ({1}).", MyTargetActor.Name, m_iOffensiveTargetID);
					}
					else
					{
						Program.Log("Invalid target selected.");
					}
					break;
				}

				/// Arbitrarily change an INI setting on the fly.
				case "gc_changesetting":
				{
					string strKey = string.Empty;
					string strValue = string.Empty;

					int iEqualsPosition = strCondensedParameters.IndexOf(" ");
					if (iEqualsPosition == -1)
						strKey = strCondensedParameters;
					else
					{
						strKey = strCondensedParameters.Substring(0, iEqualsPosition).TrimEnd();
						strValue = strCondensedParameters.Substring(iEqualsPosition + 1).TrimStart();
					}

					if (!string.IsNullOrEmpty(strKey))
					{
						Program.Log("Changing setting \"{0}\" to new value \"{1}\"...", strKey, strValue);

						IniFile FakeIniFile = new IniFile();
						FakeIniFile.WriteString(strKey, strValue);
						FakeIniFile.Mode = IniFile.TransferMode.Read;
						TransferINISettings(FakeIniFile);
						ApplySettings();
					}
					return true;
				}

				case "gc_debug":
				{
					if (astrParameters.Length == 0)
					{
						Program.Log("gc_debug: No option specified!");
						return true;
					}

					switch (astrParameters[0])
					{
						case "whopet":
							Program.Log("gc_debug whopet: Listing player's primary pet...");
							FlexStringBuilder ThisBuilder = new FlexStringBuilder();
							AppendActorInfo(ThisBuilder, 1, Me.Pet());
							Program.Log("{0}", ThisBuilder.ToString());
							return true;
					}

					Program.Log("gc_debug options: whopet");
					return true;
				}

				case "gc_exit":
				{
					Program.Log("Exit command received!");
					Program.s_bContinueBot = false;
					return true;
				}

				case "gc_findactor":
				{
					if (string.IsNullOrEmpty(strCondensedParameters))
					{
						Program.Log("gc_findactor failed: No actor name specified!");
						return true;
					}

					string strSearchString = strCondensedParameters.ToLower();
					bool bNamedSearch = (strSearchString == "named");

					List<Actor> ActorList = new List<Actor>();
					int iValidActorCount = 0;
					int iInvalidActorCount = 0;

					foreach (Actor ThisActor in Program.EnumActors())
					{
						bool bAddThisActor = false;

						if (ThisActor.IsValid)
						{
							if (bNamedSearch)
							{
								if (ThisActor.IsNamed && !ThisActor.IsAPet)
									bAddThisActor = true;
							}
							else if (ThisActor.Name.ToLower().Contains(strSearchString))
								bAddThisActor = true;
						}

						if (bAddThisActor)
						{
							ActorList.Add(ThisActor);
							iValidActorCount++;
						}
						else
							iInvalidActorCount++;
					}

					if (ActorList.Count == 0)
					{
						Program.Log("gc_findactor: Unable to find actor \"{0}\".", strCondensedParameters);
						return true;
					}

					ActorList.Sort(new ActorDistanceComparer());

					/// Run the waypoint on the nearest actor.
					Program.RunCommand("/waypoint {0}, {1}, {2}", ActorList[0].X, ActorList[0].Y, ActorList[0].Z);

					FlexStringBuilder SummaryBuilder = new FlexStringBuilder();
					SummaryBuilder.AppendLine("gc_findactor: {0} actor(s) found ({1} invalid) using \"{2}\".", iValidActorCount, iInvalidActorCount, strCondensedParameters);

					/// Now display the individual results.
					for (int iIndex = 0; iIndex < ActorList.Count && iIndex < 5; iIndex++)
					{
						Actor ThisActor = ActorList[iIndex];
						AppendActorInfo(SummaryBuilder, iIndex + 1, ThisActor);
					}

					Program.Log(SummaryBuilder.ToString());
					return true;
				}

				case "gc_openini":
				{
					Program.SafeShellExecute(Program.s_strCurrentINIFilePath);
					return true;
				}

				case "gc_openoverridesini":
				{
					Program.SafeShellExecute(Program.s_strSharedOverridesINIFilePath);
					return true;
				}

				case "gc_reloadsettings":
				{
					ReadINISettings();
					Program.ReleaseAllKeys(); /// If there's a bug, this will cure it. If not, no loss.
					Program.s_bRefreshKnowledgeBook = true;
					return true;
				}

				case "gc_stance":
				{
					if (astrParameters.Length < 1)
					{
						Program.Log("gc_stance failed: Missing stance parameter.");
						return true;
					}

					string strStance = astrParameters[0].ToLower();
					switch (strStance)
					{
						case "afk":
							Program.Log("Now ignoring all non-stance commands.");
							ChangePositioningStance(PositioningStance.DoNothing);
							break;
						case "normal":
						case "follow":
							Program.Log("Positioning is now regular auto-follow.");
							ChangePositioningStance(PositioningStance.AutoFollow);
							break;
						case "neutral":
							Program.Log("Positioning is now neutral.");
							ChangePositioningStance(PositioningStance.NeutralPosition);
							break;
						case "dash":
							Program.Log("Dashing forward.");
							ChangePositioningStance(PositioningStance.ForwardDash);
							break;
						case "stay":
							Program.Log("Staying in place.");
							m_strPositionalCommandingPlayer = Me.Name;
							ChangePositioningStance(PositioningStance.StayInPlace);
							break;
						default:
							Program.Log("Stance not recognized.");
							break;
					}

					return true;
				}

				case "gc_spawnwatch":
				{
					m_bSpawnWatchTargetAnnounced = false;
					m_strSpawnWatchTarget = strCondensedParameters.ToLower().Trim();
					Program.Log("Bot will now scan for actor \"{0}\".", m_strSpawnWatchTarget);
					ChangePositioningStance(PositioningStance.SpawnWatch);
					return true;
				}

				/// Test the text-to-speech synthesizer using the current settings.
				case "gc_tts":
				{
					Program.SayText(strCondensedParameters);
					return true;
				}

				case "gc_version":
				{
					Program.DisplayVersion();
					return true;
				}

				/// Clear the offensive target.
				case "gc_withdraw":
				{
					Program.Log("Offensive target withdrawn.");
					WithdrawFromCombat();
					return true;
				}
			}

			return false;
		}
	}
}