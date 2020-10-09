import com.GameInterface.AccountManagement;
import com.GameInterface.Chat;
import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Character;
import com.GameInterface.Game.Dynel;
import com.GameInterface.Nametags;
import com.GameInterface.VicinitySystem;
import com.GameInterface.WaypointInterface;
import com.Utils.Archive;
import com.Utils.ID32;
import com.Utils.LDBFormat;
import com.Utils.SignalGroup;
import com.Utils.WeakList;
import flash.geom.Point;
import mx.utils.Delegate;

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
var TrackHE:DistributedValue;
var m_loaded:Boolean;
var m_Enabled:Boolean;

var m_signals:SignalGroup;

var Uta:String = LDBFormat.LDBGetText(51000,35793);
var Brutus:String = LDBFormat.LDBGetText(51000,36931);
var Cassius:String = LDBFormat.LDBGetText(51000,36932);
var Iscariot:String = LDBFormat.LDBGetText(51000,36933);

function onLoad() 
{
	m_signals = new SignalGroup();
	m_Character = UtaBar.m_Character = Character.GetClientCharacter();
	rPos = DistributedValue.Create( "UtaMadre_RiflePos" );
	sPos = DistributedValue.Create( "UtaMadre_SwordPos" );	
	bPos = DistributedValue.Create( "UtaMadre_BloodPos" );
	
	rS = DistributedValue.Create( "UtaMadre_RifleScale" );
	bS = DistributedValue.Create( "UtaMadre_BloodScale" );
	sS = DistributedValue.Create( "UtaMadre_SwordScale" );
	TrackHE = DistributedValue.Create( "UtaMadre_TrackHE" );
	WaypointInterface.SignalPlayfieldChanged.Connect(SlotPlayfieldChanged, this);
}

function onUnload() 
{
	WaypointInterface.SignalPlayfieldChanged.Disconnect(SlotPlayfieldChanged, this);
	EnableAddon(false);
}

function OnModuleActivated(config:Archive)
{
	if(!m_loaded)
	{
		sPos.SetValue(config.FindEntry("SwordPos", new Point(15, 60)));
		bPos.SetValue(config.FindEntry("BloodPos", new Point(15, 165)));
		rPos.SetValue(config.FindEntry("RiflePos", new Point(15, 270)));
		
		rS.SetValue(config.FindEntry("RifleScale", 100));
		bS.SetValue(config.FindEntry("BloodScale", 100));
		sS.SetValue(config.FindEntry("SwordScale", 100));
		TrackHE.SetValue(config.FindEntry("TrackHE", false));
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
	config.AddEntry("SwordScale", sS.GetValue());
	config.AddEntry("TrackHE",TrackHE.GetValue());
	return config;
}

function SlotPlayfieldChanged(newPlayfield:Number)
{
	if (AccountManagement.GetInstance().GetLoginState() != _global.Enums.LoginState.e_LoginStateInPlay){
		setTimeout(Delegate.create(this, SlotPlayfieldChanged), 1000, newPlayfield);
		return
	}
	if(m_loaded)
	{
		// 6892: PH Elite & NM
		switch(newPlayfield)
		{
			case 6892: // PH,nametags
				setTimeout(Delegate.create(this, EnableAddon), 1000, true, true);
				return
			case 5160 && TrackHE.GetValue():
				setTimeout(Delegate.create(this, EnableAddon), 1000, true, false);
				return
			default:
				EnableAddon(false),
		}
	}
}

function EnableAddon(enabled:Boolean, nametags:Boolean)
{
	m_signals.DisconnectAll();
	ResetTargets();
	UtaBar.m_Enabled = enabled;
	if (enabled)
	{
		// to detect utas
		m_Character.SignalCharacterDied.Connect(m_signals, ResetTargets, this);
		m_Character.SignalOffensiveTargetChanged.Connect(m_signals, SlotOffensiveTargetChanged, this);
		if (nametags){
			Nametags.SignalNametagAdded.Connect(m_signals, SlotOffensiveTargetChanged, this);
			Nametags.RefreshNametags();
		}
		VicinitySystem.SignalDynelEnterVicinity.Connect(m_signals, SlotOffensiveTargetChanged, this);
		
		var ls:WeakList = Dynel.s_DynelList
		for (var num = 0; num < ls.GetLength(); num++) {
			var dyn:Character = ls.GetObject(num);
			if(dyn.GetDistanceToPlayer() < 50) SlotOffensiveTargetChanged(dyn.GetID());
		}
	}
}

function ResetTargets()
{
	m_RUTA.SetUta(null);
	m_BUTA.SetUta(null);
	m_SUTA.SetUta(null);
}

function SlotOffensiveTargetChanged(targetId:ID32)
{
	if (targetId.IsNull()) return;
	var target:Character = Character.GetCharacter(targetId);
	if (!target) return;
	
	switch(target.GetName()){
		case Uta:
			var stat = target.GetStat(112);
			var HasSword:Boolean = (stat == 35793 || stat == 35694);
			var HasRifle:Boolean = (stat == 35795 || stat == 35695);
			var HasBlood:Boolean = (stat == 35794 || stat == 35693);
			if (HasSword && !m_SUTA.GetUtaID().Equal(targetId))
			{
				m_SUTA.SetUta(target, 0xE607EB, "Blade-Uta");
			}
			else if (HasBlood && !m_BUTA.GetUtaID().Equal(targetId))
			{
				m_BUTA.SetUta(target, 0x851100, "Blood-Uta")
			}
			else if (HasRifle && !m_RUTA.GetUtaID().Equal(targetId))
			{
				m_RUTA.SetUta(target, 0x004D87, "Rifle-Uta")
			}
			//UtilsBase.PrintChatText("Uta " + target.GetStat(112) + " " + Math.floor(target.GetPosition().x) + " , " + Math.floor(target.GetPosition().z)); 
			return
		case Brutus:
			if (!m_SUTA.GetUtaID().Equal(targetId))
			{
				m_SUTA.SetUta(target, undefined, Brutus);
			}
			return
		case Cassius:
			if (!m_BUTA.GetUtaID().Equal(targetId))
			{
				m_BUTA.SetUta(target, undefined, Cassius);
			}
			return
		case Iscariot:
			if (!m_RUTA.GetUtaID().Equal(targetId))
			{
				m_RUTA.SetUta(target, undefined, Iscariot);
			}
			return
		default:
			return
	}
}