import com.GameInterface.Chat;
import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Character;
import com.GameInterface.Game.Dynel;
import com.GameInterface.VicinitySystem;
import com.GameInterface.WaypointInterface;
import com.Utils.Archive;
import com.Utils.ID32;
import com.Utils.WeakList;
import flash.geom.Point;

var m_Character:Character

var m_RUTA:UtaBar;
var m_BUTA:UtaBar;
var m_SUTA:UtaBar;
var rPos:DistributedValue;
var sPos:DistributedValue;
var bPos:DistributedValue;
var rS:DistributedValue;
var bS:DistributedValue;
var sS:DistributedValue;
var m_loaded:Boolean;

var m_ID:Array;

function UtaMadre()
{

}

function onLoad() 
{
	rPos = DistributedValue.Create( "UtaMadre_RiflePos" );
	sPos = DistributedValue.Create( "UtaMadre_SwordPos" );	
	bPos = DistributedValue.Create( "UtaMadre_BloodPos" );
	
	rS = DistributedValue.Create( "UtaMadre_RifleScale" );
	bS = DistributedValue.Create( "UtaMadre_BloodScale" );
	sS = DistributedValue.Create( "UtaMadre_SwordScale" );
	WaypointInterface.SignalPlayfieldChanged.Connect(SlotPlayfieldChanged, this);
	m_Character = Character.GetClientCharacter();
}

function onUnload() 
{
	WaypointInterface.SignalPlayfieldChanged.Disconnect(SlotPlayfieldChanged, this);
}

function OnModuleActivated(config:Archive)
{
	if(!m_loaded)
	{
		rPos.SetValue(config.FindEntry("RiflePos", new Point(15,270)));
		bPos.SetValue(config.FindEntry("BloodPos", new Point(15,165)));
		sPos.SetValue(config.FindEntry("SwordPos", new Point(15,60)));
		rS.SetValue(config.FindEntry("RifleScale", 100));
		bS.SetValue(config.FindEntry("BloodScale", 100));
		sS.SetValue(config.FindEntry("SwordScale", 100));
		m_RUTA._x = rPos.GetValue().x;
		m_RUTA._y = rPos.GetValue().y;
		m_RUTA._xscale = m_RUTA._yscale = rS.GetValue();
		
		m_BUTA._x = bPos.GetValue().x;
		m_BUTA._y = bPos.GetValue().y;
		m_BUTA._xscale = m_BUTA._yscale = bS.GetValue();
		
		m_SUTA._x = sPos.GetValue().x;
		m_SUTA._y = sPos.GetValue().y;
		m_SUTA._xscale = m_SUTA._yscale = sS.GetValue();
		m_loaded = true;
		
		SlotPlayfieldChanged(m_Character.GetPlayfieldID());
	}
}

function OnModuleDeactivated()
{
	var config:Archive = new Archive();
	config.AddEntry("RiflePos",rPos.GetValue());
	config.AddEntry("BloodPos",bPos.GetValue());
	config.AddEntry("SwordPos",sPos.GetValue());
	config.AddEntry("RifleScale",rS.GetValue());
	config.AddEntry("BloodScale",bS.GetValue());
	config.AddEntry("SwordScale",sS.GetValue());
	return config;
}

function SlotPlayfieldChanged(newPlayfield:Number)
{
	if(m_loaded)
	{
		// 6892: PH Elite & NM
		EnableAddon(newPlayfield == 6892);
	}
}

function EnableAddon(enabled:Boolean)
{
	if (enabled)
	{
		// to detect utas
		m_Character.SignalCharacterDied.Connect(ResetTargets, this);
		m_Character.SignalOffensiveTargetChanged.Connect(SlotOffensiveTargetChanged, this);
		VicinitySystem.SignalDynelEnterVicinity.Connect(SlotOffensiveTargetChanged, this);
		var ls:WeakList = Dynel.s_DynelList
		for (var num = 0; num < ls.GetLength(); num++) {
			var dyn:Character = ls.GetObject(num);
			SlotOffensiveTargetChanged(dyn.GetID());
		}
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
	m_RUTA.SetUta(null);
	m_BUTA.SetUta(null);
	m_SUTA.SetUta(null);
	
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
	
	var HasBlood:Boolean = target.GetStat(112) == 35794;
	var HasSword:Boolean = target.GetStat(112) == 35793;
	var HasRifle:Boolean = target.GetStat(112) == 35795;
	
	if (HasSword)
	{
		m_SUTA.SetUta(target, 0xE607EB);
	}
	else if (HasRifle)
	{
		m_RUTA.SetUta(target, 0x004D87)
	}
	else if (HasBlood)
	{
		m_BUTA.SetUta(target, 0x851100)
	}
}