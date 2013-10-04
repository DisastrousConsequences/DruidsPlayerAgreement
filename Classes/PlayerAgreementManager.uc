/*
    Copyright (C) 2005  Clinton H Goudie-Nice aka TheDruidXpawX

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

class PlayerAgreementManager extends Actor
	config(PlayerAgreement);

var config String Agreement;
var config String Timestamp;
var config int Timeout;
var config int YesButtonEnableTime;

var bool wasSpectator;
var bool agreed;
var bool showingPage;
var bool initialized;

var PlayerController ActivePlayer;

//sometimes through some weird events, ActivePlayer is set to None. This is a copy that's server side only.
var PlayerController ServerActivePlayer; 

var PlayerAgreementServerActor PlayerAgreementServerActor;

var String Entry;

replication
{
	reliable if (bNetDirty && Role == ROLE_Authority)
		showingPage;
	reliable if (Role == ROLE_Authority)
		PlayerAgreement, ActivePlayer, ForceCloseMenu, addToAgreement, doneAdding;
	reliable if (Role < ROLE_Authority)
		yes, showPage, no, failed;
}

function setup(PlayerController pc)
{
	local array<string> lines;
	local int i;

	if(pc == None)
		Destroy(); //how could this happen?!

	setOwner(pc); //just to be sure.
	agreed = false;
	Lifespan = Timeout;
	ActivePlayer = pc;
	ServerActivePlayer = pc;
	showingPage = false;

	wasSpectator = ServerActivePlayer.PlayerReplicationInfo.bOnlySpectator;

	if(!wasSpectator)
	{
		if (ServerActivePlayer.Pawn != None)
			ServerActivePlayer.Pawn.Died(None, class'DamageType', ServerActivePlayer.Pawn.Location);

		ServerActivePlayer.PlayerReplicationInfo.bOnlySpectator = true; //prevents them from spawning.
		ServerActivePlayer.GotoState('Spectating');
	}
	initialized = true;

	PlayerAgreement();
	//break up the string here

	Split(Agreement, "|", lines);

	for ( i = 0; i < lines.Length; i++ )
		addToAgreement(lines[i]);

	doneAdding(YesButtonEnableTime);
}

simulated function addToAgreement(String text)
{
	Local PlayerAgreementPage pap;

	if(ActivePlayer != None && ActivePlayer.player != None && ActivePlayer.player.GUIController != None)
	{
		pap = PlayerAgreementPage(GUIController(ActivePlayer.player.GUIController).TopPage());
		if(pap != None)
		{
			if(text == "")
				pap.appendText("|");
			else
				pap.appendText(text);
		}
		else
		{
			log("PAM: No PAP at AddToAgreement. Failing.");
			failed();
		}
	}
	else
	{
		log("PAM: No Player at AddToAgreement. Failing.");
		failed();
	}
}

simulated function doneAdding(int lYesButtonEnableTime)
{
	Local PlayerAgreementPage pap;

	if(ActivePlayer != None && ActivePlayer.player != None && ActivePlayer.player.GUIController != None)
	{
		pap = PlayerAgreementPage(GUIController(ActivePlayer.player.GUIController).TopPage());
		if(pap != None)
			pap.doneAddingText(lYesButtonEnableTime);
		else
		{
			log("PAM: No PAP at DoneAdding. Failing.");
			failed();
		}
	}
	else
	{
		log("PAM: No Player at DoneAdding. Failing.");
		failed();
	}
}

function yes()
{
	local PlayerAgreement PlayerAgreement;
	PlayerAgreement = new(None, Entry) class'PlayerAgreement';
	PlayerAgreement.Timestamp = Timestamp;

	PlayerAgreement.SaveConfig();
	agreed = true;

	Log("PAM:" @ ActivePlayer.getPlayerIDHash() @ ActivePlayer.PlayerReplicationInfo.GetHumanReadableName() @ "pressed yes");
	showingPage = false;

	Destroy();
}

function no()
{
	local PlayerAgreement PlayerAgreement;
	PlayerAgreement = new(None, Entry) class'PlayerAgreement';
	PlayerAgreement.Timestamp = "Answered No";
	PlayerAgreement.SaveConfig();

	Log("PAM:" @ ActivePlayer.getPlayerIDHash() @ ActivePlayer.PlayerReplicationInfo.GetHumanReadableName() @ "pressed No");
	showingPage = false;
	setOwner(None);

	Destroy();
}

function failed()
{
	local PlayerAgreement PlayerAgreement;
	PlayerAgreement = new(None, Entry) class'PlayerAgreement';
	PlayerAgreement.Timestamp = "Unable to Answer";
	PlayerAgreement.SaveConfig();

	agreed = true;
	showingPage = false;
	Log("PAM:" @ ActivePlayer.getPlayerIDHash() @ ActivePlayer.PlayerReplicationInfo.GetHumanReadableName() @ "failed to run.");
	ForceCloseMenu();

	PlayerAgreementServerActor.failed();
	Destroy();
}

function showPage()
{
	showingPage = true;
}

simulated function PlayerAgreement()
{
	Local PlayerAgreementPage pap;
	if(showingPage)
		return;

	if(ActivePlayer != None && ActivePlayer.player != None && ActivePlayer.player.GUIController != None)
	{
		showPage();

		ActivePlayer.player.GUIController.OpenMenu("DruidsPlayerAgreement110.PlayerAgreementPage");

		pap = PlayerAgreementPage(GUIController(ActivePlayer.player.GUIController).TopPage());
		if(pap != None)
			pap.pam = self;
		else
		{
			log("PAM: No PAP at PlayerAgreement. Failing.");
			failed();
		}
	}
	else
	{
		log("PAM: No Player at PlayerAgreement. Failing.");
		failed();
	}
}

simulated function ForceCloseMenu()
{
	Local PlayerAgreementPage pap;
	if(ActivePlayer != None && ActivePlayer.player != None && ActivePlayer.player.GUIController != None)
	{
		pap = PlayerAgreementPage(GUIController(ActivePlayer.player.GUIController).TopPage());
		if(pap != None)
		{
			pap.myclosed = true;
			pap.pam = None;
			pap.Controller.CloseMenu(false);
		}
	}
}

event destroyed()
{
	if(!wasSpectator && !agreed && initialized || initialized && ServerActivePlayer == none)
	{
		Level.Game.NumPlayers--; //have to subtract from the players since when they leave they're a spectator
		Level.Game.NumSpectators++; //have to add to spectators since when they leave they're in spectator mode
	}

	if(ServerActivePlayer != none)
	{
	        if(agreed)
		{
			if(!wasSpectator)
			{
				ServerActivePlayer.bBehindView = false;
				ServerActivePlayer.FixFOV();
				ServerActivePlayer.ServerViewSelf();
				ServerActivePlayer.PlayerReplicationInfo.bOnlySpectator = false;
				ServerActivePlayer.PlayerReplicationInfo.Reset();
				ServerActivePlayer.Adrenaline = 0;
				ServerActivePlayer.BroadcastLocalizedMessage(Level.Game.GameMessageClass, 1, ServerActivePlayer.PlayerReplicationInfo);
				ServerActivePlayer.GotoState('PlayerWaiting');
				if (Level.Game.bTeamGame)
   			     		Level.Game.ChangeTeam(ServerActivePlayer, Level.Game.PickTeam(int(ServerActivePlayer.GetURLOption("Team")), None), false);
			}
		}
		else
		{
			ForceCloseMenu();
			ServerActivePlayer.ClientNetworkMessage("AC_Kicked", "You must accept the agreement to play on this server");
			if (ServerActivePlayer.Pawn != None)
				ServerActivePlayer.Pawn.Destroy();
			ServerActivePlayer.Destroy();
			class'PlayerAgreementServerActor'.static.RemoveAgreement(ServerActivePlayer);
		}
	}
	super.Destroyed();
}

defaultproperties
{
     agreement="Server Admin|should have a message here."
     TimeStamp="MM-DD-YYYY"
     TimeOut=90
     YesButtonEnableTime=20
     RemoteRole=ROLE_SimulatedProxy
     NetUpdateFrequency=0.250000
     NetPriority=3.000000
}