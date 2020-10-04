import com.GameInterface.Chat;
import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Character;
import com.GameInterface.VicinitySystem;
import com.GameInterface.WaypointInterface;
import com.Utils.Archive;
import com.Utils.ID32;

var m_Character:Character

var m_PUTA:UtaBar;
var m_CUTA:UtaBar;
var m_DUTA:UtaBar;

var m_ID:Array;

function OnModuleActivated(config:Archive)
{
	var pX:DistributedValue = DistributedValue.Create( "PutaX" );
	var pY:DistributedValue = DistributedValue.Create( "PutaY" );	
	var dX:DistributedValue = DistributedValue.Create( "DutaX" );
	var dY:DistributedValue = DistributedValue.Create( "DutaY" );	
	var cX:DistributedValue = DistributedValue.Create( "CutaX" );
	var cY:DistributedValue = DistributedValue.Create( "CutaY" );	
	
	var pS:DistributedValue = DistributedValue.Create( "PutaScale" );
	var dS:DistributedValue = DistributedValue.Create( "DutaScale" );
	var cS:DistributedValue = DistributedValue.Create( "CutaScale" );
	
	m_PUTA._x = pX.GetValue();
	m_PUTA._y = pY.GetValue();
	m_PUTA._xscale = m_PUTA._yscale = pS.GetValue();
	
	m_DUTA._x = dX.GetValue();
	m_DUTA._y = dY.GetValue();
	m_DUTA._xscale = m_DUTA._yscale = dS.GetValue();
	
	m_CUTA._x = cX.GetValue();
	m_CUTA._y = cY.GetValue();
	m_CUTA._xscale = m_CUTA._yscale = cS.GetValue();
	
	WaypointInterface.SignalPlayfieldChanged.Connect(SlotPlayfieldChanged, this);
	
	m_Character = Character.GetClientCharacter();
	SlotPlayfieldChanged(m_Character.GetPlayfieldID());
}

function OnModuleDeactivated()
{
	
}

function SlotPlayfieldChanged(newPlayfield:Number)
{
	// 6892: PH Elite & NM
	EnableAddon(newPlayfield == 6892);
}

function EnableAddon(enabled:Boolean)
{
	if (enabled)
	{
		// to detect utas
		m_Character.SignalCharacterDied.Connect(ResetTargets, this);
		m_Character.SignalOffensiveTargetChanged.Connect(SlotOffensiveTargetChanged, this);
		VicinitySystem.SignalDynelEnterVicinity.Connect(SlotOffensiveTargetChanged, this);
	}
	else
	{
		m_Character.SignalCharacterDied.Disconnect(ResetTargets, this);
		m_Character.SignalOffensiveTargetChanged.Disconnect(SlotOffensiveTargetChanged, this);
		VicinitySystem.SignalDynelEnterVicinity.Disconnect(SlotOffensiveTargetChanged, this);
	}
	
	ResetTargets();
}

function ResetTargets()
{
	m_PUTA.SetUta(null);
	m_DUTA.SetUta(null);
	m_CUTA.SetUta(null);
	
	m_ID = new Array();
}

function SlotOffensiveTargetChanged(targetId:ID32)
{
	var target:Character = Character.GetCharacter(targetId);
	if (target.GetName() != "Uta")
		return;
	
	// ID -> Type: 50000 - Instance: xxxxx
	if (m_ID.length < 3 && !targetId.Equal(m_ID[0]) && !targetId.Equal(m_ID[1]))
		m_ID.push(targetId);
	else
		return;
	
	var HasPink:Boolean = target.GetStat(_global.Enums.Stat.e_CurrentPinkShield, 2) != 0;
	var HasBlue:Boolean = target.GetStat(_global.Enums.Stat.e_CurrentBlueShield, 2) != 0;
	var HasRed:Boolean = target.GetStat(_global.Enums.Stat.e_CurrentRedShield, 2) != 0;
	
	if (HasBlue)
	{
		m_CUTA.SetUta(target, 0x004D87);
	}
	else if (HasPink)
	{
		
		m_PUTA.SetUta(target, 0x870087)
	}
	else if (HasRed)
	{
		
		m_DUTA.SetUta(target, 0x851100)
	}
}