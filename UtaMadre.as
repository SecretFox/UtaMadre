import com.GameInterface.AccountManagement;
import com.GameInterface.Chat;
import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Character;
import com.GameInterface.Game.Dynel;
import com.GameInterface.Inventory;
import com.GameInterface.InventoryItem;
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

var d_rPos:DistributedValue;
var d_sPos:DistributedValue;
var d_bPos:DistributedValue;
var d_rS:DistributedValue;
var d_bS:DistributedValue;
var d_sS:DistributedValue;

var d_trackHE:DistributedValue;
var d_honorSound:DistributedValue;
var d_important:DistributedValue;
var d_markUta:DistributedValue;
var d_bombSound:DistributedValue;

var modLoaded:Boolean;
var modEnabled:Boolean;
var markerItems:Array = [];
var targetSignals:SignalGroup;

var Uta:String = LDBFormat.LDBGetText(51000,35793);
var Brutus:String = LDBFormat.LDBGetText(51000,36931);
var Cassius:String = LDBFormat.LDBGetText(51000,36932);
var Iscariot:String = LDBFormat.LDBGetText(51000, 36933);

function onLoad()
{
	targetSignals = new SignalGroup();
	m_Character = UtaBar.m_Character = Character.GetClientCharacter();
	d_rPos = DistributedValue.Create( "UtaMadre_RiflePos" );
	d_sPos = DistributedValue.Create( "UtaMadre_SwordPos" );
	d_bPos = DistributedValue.Create( "UtaMadre_BloodPos" );

	d_rS = DistributedValue.Create( "UtaMadre_RifleScale" );
	d_bS = DistributedValue.Create( "UtaMadre_BloodScale" );
	d_sS = DistributedValue.Create( "UtaMadre_SwordScale" );

	d_important = DistributedValue.Create( "UtaMadre_ImportantCastsOnly" );
	d_markUta = DistributedValue.Create("UtaMadre_MarkUta");

	d_trackHE = DistributedValue.Create( "UtaMadre_TrackHE" );
	d_honorSound = DistributedValue.Create("UtaMadre_HonorableSound");
	d_bombSound = DistributedValue.Create("UtaMadre_BombSound");
	WaypointInterface.SignalPlayfieldChanged.Connect(SlotPlayfieldChanged, this);
}

function onUnload()
{
	WaypointInterface.SignalPlayfieldChanged.Disconnect(SlotPlayfieldChanged, this);
	EnableAddon(false);
}

function OnModuleActivated(config:Archive)
{
	if (!modLoaded)
	{
		d_sPos.SetValue(config.FindEntry("SwordPos", new Point(15, 60)));
		d_bPos.SetValue(config.FindEntry("BloodPos", new Point(15, 165)));
		d_rPos.SetValue(config.FindEntry("RiflePos", new Point(15, 270)));

		d_rS.SetValue(config.FindEntry("RifleScale", 100));
		d_bS.SetValue(config.FindEntry("BloodScale", 100));
		d_sS.SetValue(config.FindEntry("SwordScale", 100));

		d_trackHE.SetValue(config.FindEntry("TrackHE", false));
		d_important.SetValue(config.FindEntry("Important", true));
		d_markUta.SetValue(config.FindEntry("Mark", false));
		d_honorSound.SetValue(config.FindEntry("HonorableSound", false));
		d_bombSound.SetValue(config.FindEntry("BombSound", true));

		
		
		m_RUTA._x = d_rPos.GetValue().x;
		m_RUTA._y = d_rPos.GetValue().y;
		m_RUTA._xscale = m_RUTA._yscale = d_rS.GetValue();

		m_BUTA._x = d_bPos.GetValue().x;
		m_BUTA._y = d_bPos.GetValue().y;
		m_BUTA._xscale = m_BUTA._yscale = d_bS.GetValue();

		m_SUTA._x = d_sPos.GetValue().x;
		m_SUTA._y = d_sPos.GetValue().y;
		m_SUTA._xscale = m_SUTA._yscale = d_sS.GetValue();
		modLoaded = true;

		SlotPlayfieldChanged(m_Character.GetPlayfieldID());
	}
}

function OnModuleDeactivated()
{
	var config:Archive = new Archive();
	config.AddEntry("RiflePos",d_rPos.GetValue());
	config.AddEntry("BloodPos",d_bPos.GetValue());
	config.AddEntry("SwordPos",d_sPos.GetValue());
	config.AddEntry("RifleScale",d_rS.GetValue());
	config.AddEntry("BloodScale",d_bS.GetValue());
	config.AddEntry("SwordScale", d_sS.GetValue());
	config.AddEntry("TrackHE",d_trackHE.GetValue());
	config.AddEntry("HonorableSound",d_honorSound.GetValue());
	config.AddEntry("BombSound", d_bombSound.GetValue());
	config.AddEntry("Important", d_important.GetValue());
	config.AddEntry("Mark",d_markUta.GetValue());
	return config;
}

function SlotPlayfieldChanged(newPlayfield:Number)
{
	if (AccountManagement.GetInstance().GetLoginState() != _global.Enums.LoginState.e_LoginStateInPlay)
	{
		setTimeout(Delegate.create(this, SlotPlayfieldChanged), 1000, newPlayfield);
		return
	}
	if (modLoaded)
	{
		// 6892: PH Elite & NM
		switch (newPlayfield)
		{
			case 6892: // PH,nametags
				setTimeout(Delegate.create(this, EnableAddon), 1000, true, true);
				return;
			case 5160:
				if (d_trackHE.GetValue())
				{
					setTimeout(Delegate.create(this, EnableAddon), 1000, true, false);
					return
				}
			default:
				EnableAddon(false);
		}
	}
}

function EnableAddon(enabled:Boolean, nametags:Boolean)
{
	targetSignals.DisconnectAll();
	ResetTargets();
	UtaBar.modEnabled = enabled;
	if (enabled)
	{
		// to detect utas
		m_Character.SignalCharacterDied.Connect(targetSignals, ResetTargets, this);
		m_Character.SignalOffensiveTargetChanged.Connect(targetSignals, SlotOffensiveTargetChanged, this);
		if (nametags)
		{
			SaveMarks();
			Nametags.SignalNametagAdded.Connect(targetSignals, SlotOffensiveTargetChanged, this);
			Nametags.RefreshNametags();
		}
		VicinitySystem.SignalDynelEnterVicinity.Connect(targetSignals, SlotOffensiveTargetChanged, this);
		var ls:WeakList = Dynel.s_DynelList;
		for (var num = 0; num < ls.GetLength(); num++)
		{
			var dyn:Character = ls.GetObject(num);
			if (dyn.GetDistanceToPlayer() < 50) SlotOffensiveTargetChanged(dyn.GetID());
		}
	}
	else
	{
		_root.backpack2.m_QuestInventory.SignalItemMoved.Disconnect(SaveMarks, this);
		_root.backpack2.m_QuestInventory.SignalItemAdded.Disconnect(SaveMarks, this);
	}
}

function ResetTargets()
{
	m_RUTA.SetUta(null);
	m_BUTA.SetUta(null);
	m_SUTA.SetUta(null);
}

function SaveMarks()
{
	markerItems = [[],[],[]];
	var playerInventory:Inventory = _root.backpack2.m_QuestInventory;
	for (var i = 0; i < playerInventory.GetMaxItems(); i++)
	{
		var item:InventoryItem = playerInventory.GetItemAt(i);
		switch (item.m_ACGItem.m_TemplateID0)
		{
			case 7603289:
			case 7603290:
				markerItems[0].push(item);
				break;
			case 7603287:
			case 7603288:
				markerItems[1].push(item);
				break;
			case 7603285:
			case 7603286:
				markerItems[2].push(item);
				break;
			default:
				break;
		}
	}
	playerInventory.SignalItemMoved.Connect(SaveMarks, this);
	playerInventory.SignalItemAdded.Connect(SaveMarks, this);
}

function MarkTarget(num, targetId:ID32)
{
	if (!Character.GetClientCharacter().GetOffensiveTarget().Equal(targetId)) return;
	var playerInventory:Inventory = _root.backpack2.m_QuestInventory;
	switch (num)
	{
		case 0:
			if (markerItems[0][0]) playerInventory.UseItem(InventoryItem(markerItems[0][0]).m_InventoryPos);
			break;
		case 1:
			if (markerItems[1][0]) playerInventory.UseItem(InventoryItem(markerItems[1][0]).m_InventoryPos);
			break;
		case 2:
			if (markerItems[2][0]) playerInventory.UseItem(InventoryItem(markerItems[2][0]).m_InventoryPos);
			break;
		default:
			break;
	}
}

function SlotOffensiveTargetChanged(targetId:ID32)
{
	if (targetId.IsNull()) return;
	var target:Character = Character.GetCharacter(targetId);
	switch (target.GetName())
	{
		case Uta:
			switch (target.GetStat(112))
			{
				case 35793:
				case 35694:
					if (d_markUta.GetValue()) MarkTarget(0, targetId);
					if (!m_SUTA.GetUtaID().Equal(targetId)) m_SUTA.SetUta(target, 0x009900, "Blade-Uta");
					break;
				case 35794:
				case 35693:
					if (d_markUta.GetValue()) MarkTarget(1, targetId);
					if (!m_BUTA.GetUtaID().Equal(targetId)) m_BUTA.SetUta(target, 0x851100, "Blood-Uta");
					break;
				case 35795:
				case 35695:
					if (d_markUta.GetValue()) MarkTarget(2, targetId);
					if (!m_RUTA.GetUtaID().Equal(targetId)) m_RUTA.SetUta(target, 0x004D87, "Rifle-Uta");
					break;
			}
			break;
		case Brutus:
			if (!m_SUTA.GetUtaID().Equal(targetId))
			{
				m_SUTA.SetUta(target, undefined, Brutus);
			}
			break;
		case Cassius:
			if (!m_BUTA.GetUtaID().Equal(targetId))
			{
				m_BUTA.SetUta(target, undefined, Cassius);
			}
			break;
		case Iscariot:
			if (!m_RUTA.GetUtaID().Equal(targetId))
			{
				m_RUTA.SetUta(target, undefined, Iscariot);
			}
			break;
		default:
			break;
	}
}