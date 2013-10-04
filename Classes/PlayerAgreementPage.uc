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

class PlayerAgreementPage extends GUIPage;

var automated GUISectionBackground sb_Agreement, sb_Buttons;
var automated GUIScrollTextBox lb_Text;
var automated GUIButton YesButton, NoButton;

var PlayerAgreementManager pam;

//populated just prior to doneAdding
var Player Player;

var bool myclosed;
var int YesTimeout;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	super.Initcomponent(MyController, MyOwner);
	myclosed = false;
	sb_Agreement.ManageComponent(lb_Text);
	sb_Buttons.ManageComponent(YesButton);
	sb_Buttons.ManageComponent(NoButton);
	YesButton.DisableMe();
}

function bool InternalOnPreDraw(Canvas C)
{
	if(myclosed)
		return false;

	if(pam == None)
	{
		//Wild.... maybe in a minute.
		Log("PAM: No PAM!");
	}


	return false;
}

function appendText(String text)
{
	lb_Text.AddText(text);
}

function doneAddingText(int YesButtonEnableTime)
{
	YesTimeout = YesButtonEnableTime;
	SetTimer(1, true);
}

function Timer()
{
	YesTimeout -= 1;
	if(YesTimeout <= 0)
	{
		YesButton.Caption = "I agree!";
		YesButton.EnableMe();
		SetTimer(0, false);
	}
	else
	{
		YesButton.Caption = "I agree! (Enabled in " $ YesTimeout $ ")";
	}
}

// Maybe Escape hit - Don't allow!
function bool InternalOnCanClose(optional bool bCanceled)
{
	if(pam == None)
		return true;
	return myclosed;
}

function InternalOnClose(optional bool bCanceled)
{
	if(myclosed)
		return;
	
	Log("PAM: Window closed without an answer. Failing.");
	Controller.CloseMenu(false);
	if(pam != None)
		pam.failed();
}

function bool Yes(GUIComponent Sender)
{
	myclosed = true;
	Log("PAM: Yes clicked");
	if(pam != None)
		pam.yes();
	PlayerOwner().ConsoleCommand( "ADDCURRENTTOFAVORITES" ); //Enjoy your stay
	Controller.CloseMenu(false);
	return true;
}

function bool No(GUIComponent Sender)
{
	myclosed = true;
	Log("PAM: No clicked");
	Controller.CloseMenu(false);
	if(pam != None)
		pam.no();
	return true;
}

defaultproperties
{
     Begin Object Class=AltSectionBackground Name=sbAgreement
         Caption="Player Agreement"
         LeftPadding=0.000000
         RightPadding=0.000000
         FontScale=FNS_Small
         WinTop=0.030325
         WinLeft=0.035693
         WinWidth=0.922427
         WinHeight=0.694637
         bBoundToParent=True
         bScaleToParent=True
         OnPreDraw=sbAgreement.InternalPreDraw
     End Object
     sb_Agreement=AltSectionBackground'PlayerAgreementPage.sbAgreement'

     Begin Object Class=AltSectionBackground Name=sbButtons
         Caption="Choose your destiny"
         LeftPadding=0.000000
         RightPadding=0.000000
         FontScale=FNS_Small
         WinTop=0.728274
         WinLeft=0.035693
         WinWidth=0.922427
         WinHeight=0.208224
         bBoundToParent=True
         bScaleToParent=True
         OnPreDraw=sbButtons.InternalPreDraw
     End Object
     sb_Buttons=AltSectionBackground'PlayerAgreementPage.sbButtons'

     Begin Object Class=GUIScrollTextBox Name=AgreementText
         bNoTeletype=True
         CharDelay=0.002500
         EOLDelay=0.000000
         OnCreateComponent=AgreementText.InternalOnCreateComponent
         FontScale=FNS_Small
         WinTop=0.441667
         WinHeight=0.558333
         bBoundToParent=True
         bScaleToParent=True
         bNeverFocus=True
     End Object
     lb_Text=GUIScrollTextBox'PlayerAgreementPage.AgreementText'

     Begin Object Class=GUIButton Name=MyYesButton
         Caption="I agree!"
         FontScale=FNS_Small
         WinTop=0.511082
         WinLeft=0.550634
         WinWidth=0.160075
         TabOrder=1
         bBoundToParent=True
         bScaleToParent=True
         OnClick=PlayerAgreementPage.yes
         OnKeyEvent=MyYesButton.InternalOnKeyEvent
     End Object
     YesButton=GUIButton'PlayerAgreementPage.MyYesButton'

     Begin Object Class=GUIButton Name=MyNoButton
         Caption="I do not agree."
         FontScale=FNS_Small
         WinTop=0.511082
         WinLeft=0.715411
         WinWidth=0.207744
         TabOrder=2
         bBoundToParent=True
         bScaleToParent=True
         OnClick=PlayerAgreementPage.NO
         OnKeyEvent=MyNoButton.InternalOnKeyEvent
     End Object
     NoButton=GUIButton'PlayerAgreementPage.MyNoButton'

     bAllowedAsLast=True
     bRenderWorld=False

     OnCanClose=PlayerAgreementPage.InternalOnCanClose
     OnClose=PlayerAgreementPage.InternalOnClose

     WinHeight=1.000000
     OnPreDraw=PlayerAgreementPage.InternalOnPreDraw
}
