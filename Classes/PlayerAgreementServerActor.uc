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

class PlayerAgreementServerActor extends info
	config(PlayerAgreement);

var config float CheckInterval;
var int last;
var config bool UseName;

function PreBeginPlay()
{
	log("PAM: Using Druids Player Agreement");
	super.PreBeginPlay();
}

function PostBeginPlay()
{
	super.PostBeginPlay();
	last = -1;
	Enable('Tick');
	setTimer(CheckInterval, true);
}

//this catches most people on the way in
function Tick(float time)
{
	super.Tick(time);
	if(last != Level.Game.CurrentID)
		RunAgreements();

	last = Level.Game.CurrentID;
}

//this catches spectators and the stragglers
function Timer()
{
	super.Timer();
	RunAgreements();
}

function RunAgreements()
{
	local Controller c;
	local Playercontroller pc;
	local PlayerAgreement agreement;
	local PlayerAgreementManager pam;
	local PlayerAgreementInv inv;
	local String Entry;
	
	for(c = Level.ControllerList; c != None; c = c.NextController)
	{
		if(c == None || !c.isA('PlayerController'))
			continue;
		pc = PlayerController(c);

		if(pc.isA('MessagingSpectator'))
			continue;
		if(pc.isA('Camera'))
			continue;
		
		if(pc.PlayerReplicationInfo == None)
			continue; //Odd. we'll get 'em on the next pass

		Inv = FindAgreement(pc);
		if(Inv == None)
		{

			pam = spawn(class'PlayerAgreementManager', pc);
			if(pam == None)
				continue; //get em next pass
			pam.PlayerAgreementServerActor = self;
			Pam.setOwner(pc);

			Inv = spawn(class'PlayerAgreementInv', pc);
			if(inv == None)
				continue; //get em next pass;

			GiveAgreement(pc, inv);
			if(UseName)
				Entry = pc.getPlayerIDHash() @ pc.PlayerReplicationInfo.GetHumanReadableName();
			else
				Entry = pc.getPlayerIDHash();

			pam.Entry = Entry;
			agreement = new(None, Entry) class'PlayerAgreement';

			if(pam.Timestamp != agreement.Timestamp)
			{
				log("PAM: Requesting PlayerAgreement from:" @ pc.getPlayerIDHash() @ pc.PlayerReplicationInfo.GetHumanReadableName());
				pam.setup(pc);
			}
			else
			{
				pam.destroy();
			}
		}
	}
}

static function GiveAgreement(PlayerController pc, PlayerAgreementInv pinv)
{
	local Inventory Inv;
	local int Count;

	pinv.setOwner(pc);
	pc.NotifyAddInventory(pinv);

	if(pc.Inventory == None)
	{
		pc.Inventory = pinv;
		pc.NetUpdateTime = pc.Level.TimeSeconds - 1;
		return;
	}

	for(Inv=pc.Inventory; Inv != None && Inv.Inventory != None && Count < 1000; Inv=Inv.Inventory)
		Count++;

	Inv.Inventory = pinv;
	Inv.NetUpdateTime = pc.Level.TimeSeconds - 1;
}

function failed()
{
	last = -1;
}

static function PlayerAgreementInv FindAgreement(PlayerController pc)
{
	local Inventory Inv;
	local int Count;

	for(Inv=pc.Inventory; Inv != None && Count < 1000; Inv=Inv.Inventory)
	{
		if(Inv.class == class'PlayerAgreementInv')
			return PlayerAgreementInv(Inv);
		Count++;
	}

	return None;
}

static function RemoveAgreement(PlayerController pc)
{
	local Inventory Inv;
	local Inventory Last;
	local int Count;

	for(Inv=pc.Inventory; Inv != None && Count < 1000; Inv=Inv.Inventory)
	{
		if(Inv.class == class'PlayerAgreementInv')
		{
			if(Last != None)
				Last.Inventory = Inv.Inventory;
			else
				pc.Inventory = Inv.Inventory;

			Inv.Destroy();
			return;
		}
		Count++;
		Last = Inv;
	}
	log("PAM: RemoveAgreement called, but no agreement found!");
	return;
}


defaultproperties
{
	CheckInterval=10.000000
	UseName=True
}
