import com.GameInterface.Chat;
import com.GameInterface.DistributedValue;
import com.GameInterface.Game.BuffData;
import com.GameInterface.Game.Character;
import com.GameInterface.Game.TargetingInterface;
import com.GameInterface.Targeting;
import com.GameInterface.Utils;
import com.Utils.Colors;
import com.Utils.ID32;
import gfx.core.UIComponent;
import mx.utils.Delegate;
import com.Components.BuffCharge;

class UtaBar extends UIComponent
{
	private var m_HealthBar:MovieClip;
	private var m_ShieldBar:MovieClip;
	private var m_CastBar:MovieClip;
	
	private var m_Icon:MovieClip;
	private var m_SisterlyBonds:TextField;
	private var m_BuffCharge:BuffCharge;
	
	private var m_Border:MovieClip;
	
	private var m_Uta:Character;
	private var m_Character:Character;
	private var m_UtaType:String;
	
	private var m_EditModeMask:MovieClip;
	
	private var m_IntervalId:Number;
	private var m_Increments:Number;
	private var m_TotalFrames:Number; 
	private var m_StopFrame:Number;
	private var m_ProgressBarType:Number;

	private var m_MovieClipLoader:MovieClipLoader;
	
	public function UtaBar()
	{
		super();
		
		if (_name == "m_PUTA") m_UtaType = "P";
		else if (_name == "m_DUTA") m_UtaType = "D";
		else if (_name == "m_CUTA") m_UtaType = "C";
		
		m_Character = Character.GetClientCharacter();
		m_Character.SignalOffensiveTargetChanged.Connect(SlotOffensiveTargetChanged, this);
		
		m_MovieClipLoader = new MovieClipLoader();
	}
	
	// good: 0x006600
	// average: 0xFFCC00
	// bad: 0xFF3300
	
	private function configUI()
	{
		_visible = false;
		m_CastBar._visible = false;
		m_EditModeMask._visible = false;
		
		super.configUI();
		
		com.Utils.GlobalSignal.SignalSetGUIEditMode.Connect(SlotSetGUIEditMode, this);
		
		m_Increments = 20;
		m_TotalFrames = m_CastBar.m_ProgressBar._totalframes;
		m_ProgressBarType = _global.Enums.CommandProgressbarType.e_CommandProgressbar_Fill;
		m_StopFrame = ((m_ProgressBarType == _global.Enums.CommandProgressbarType.e_CommandProgressbar_Empty) ? m_TotalFrames : 1);
		m_CastBar.m_ProgressBar.gotoAndStop(m_StopFrame);
		
		this.onPress = Delegate.create(this, SlotUtaBarClicked);
		this.onRelease = this.onReleaseOutside = Delegate.create(this, SlotEditMaskReleased);
		
		m_EditModeMask.onPress = Delegate.create(this, SlotEditMaskPressed);
		m_EditModeMask.onRelease = m_EditModeMask.onReleaseOutside = Delegate.create(this, SlotEditMaskReleased);
	}
	
	private function SlotOffensiveTargetChanged(targetId:ID32)
	{
		if (targetId.Equal(m_Uta.GetID()))
			Colors.ApplyColor(m_Border, 0xEEEEEE);
		else
			Colors.ApplyColor(m_Border, 0x000000);
	}
	
	private function SlotUtaBarClicked()
	{
		if (m_EditModeMask._visible)
		{
			SlotEditMaskPressed();
			return;
		}
			
		TargetingInterface.SetTarget(m_Uta.GetID());
	}
	
	public function GetUtaID():ID32
	{
		return m_Uta.GetID();
	}
	public function SetUta(uta:Character, shieldColor:Number)
	{
		if (m_Uta != null)
		{
			m_Uta.SignalStatChanged.Disconnect(SlotStatChanged, this);
			m_Uta.SignalCommandStarted.Disconnect( SlotSignalCommandStarted, this);
			m_Uta.SignalCommandEnded.Disconnect( SlotSignalCommandEnded, this);
			m_Uta.SignalCommandAborted.Disconnect( SlotSignalCommandAborted, this);
			
			m_Uta.SignalBuffAdded.Disconnect(SlotBuffChange, this);
			m_Uta.SignalBuffRemoved.Disconnect(SlotBuffChange, this);
			m_Uta.SignalBuffUpdated.Disconnect(SlotBuffChange, this);
			
			m_Uta.SignalCharacterDied.Disconnect(SlotDeath, this);
		}
		
		m_Uta = uta;
		
		if (m_Uta != null)
		{
			m_Uta.SignalStatChanged.Connect(SlotStatChanged, this);
			m_Uta.SignalCommandStarted.Connect( SlotSignalCommandStarted, this);
			m_Uta.SignalCommandEnded.Connect( SlotSignalCommandEnded, this);
			m_Uta.SignalCommandAborted.Connect( SlotSignalCommandAborted, this);
			
			m_Uta.SignalBuffAdded.Connect(SlotBuffChange, this);
			m_Uta.SignalBuffRemoved.Connect(SlotBuffChange, this);
			m_Uta.SignalBuffUpdated.Connect(SlotBuffChange, this);
			
			m_Uta.SignalCharacterDied.Connect(SlotDeath, this);
		}
		
		Colors.ApplyColor(m_ShieldBar.m_Background, shieldColor);
		
		SlotStatChanged();
		SlotOffensiveTargetChanged(m_Uta.GetID());
		SlotBuffChange();
		
		_visible = (m_Uta != null);
		m_CastBar._visible = false;
	}
	
	private function SlotDeath()
	{
		SetUta(null);
	}
	
	private function SlotSignalCommandStarted( name:String, progressBarType:Number) : Void
	{
		m_ProgressBarType = progressBarType;
		
		if( m_CastBar.m_ProgressBar._currentframe != 1 )
		{
			clearInterval(m_IntervalId);
		}

		m_CastBar.m_ProgressBar.gotoAndStop( m_StopFrame );
		m_IntervalId = setInterval( Delegate.create( this, ExecuteCallback ), m_Increments );
		
		m_CastBar.m_Text.text = name;
		
		m_CastBar._visible = true;
	}
	private function ExecuteCallback(): Void
	{
		if (m_Uta != undefined)
		{
			var scaleNum:Number = Math.min( Math.round( m_Uta.GetCommandProgress() * m_TotalFrames ), m_TotalFrames);

			if (m_ProgressBarType == _global.Enums.CommandProgressbarType.e_CommandProgressbar_Empty)
			{
				scaleNum = m_TotalFrames - scaleNum;
			}
			m_CastBar.m_ProgressBar.gotoAndStop(scaleNum);
		}
	}
	private function SlotSignalCommandEnded() : Void
	{
		clearInterval( m_IntervalId );
		m_CastBar._visible = false;
		m_CastBar.m_ProgressBar.stop();
	}

	private function SlotSignalCommandAborted() : Void
	{
		//clearInterval( m_IntervalId );
		//m_CastBar._visible = false;
		
		m_CastBar.m_Text.text = "Interrupted!";
		_global['setTimeout'](this, 'SlotSignalCommandEnded', 500);
	}
	
	private function SlotBuffChange()
	{
		for (var buffId in m_Uta.m_BuffList)
		{
			var buff:BuffData = m_Uta.m_BuffList[buffId];
			if (buff.m_BuffId == 8963983 || buff.m_Name == "Sisterly Bonds") // Sisterly Bonds
			{
				if(buff.m_Icon != undefined && m_BuffCharge == undefined) {
					this.attachMovie( "_BuffCharge", "m_BuffCharge", this.getNextHighestDepth() );

					m_BuffCharge.SetMax( buff.m_MaxCounters );
					m_BuffCharge.SetColor( 0x0000ff );

					//m_BuffCharge._x = 28;
					//m_BuffCharge._y = 80;
					
					m_BuffCharge._xscale = m_BuffCharge._yscale = 160;
					m_BuffCharge._x = 25;
					m_BuffCharge._y = 79;
				}
				
				m_BuffCharge.SetCharge( Math.max(1, buff.m_Count) );
				
				
				
				switch(buff.m_Count)
				{
					case 0:
					case 1:
						Colors.ApplyColor(m_BuffCharge.i_Offset.i_PosLayer.i_ScaleLayer.i_MainLayer.i_Back.i_TintLayer, 0x33FF33); 
						break;
					case 2:
						Colors.ApplyColor(m_BuffCharge.i_Offset.i_PosLayer.i_ScaleLayer.i_MainLayer.i_Back.i_TintLayer, 0xFFCC00); 
						break;
					case 3:
						Colors.ApplyColor(m_BuffCharge.i_Offset.i_PosLayer.i_ScaleLayer.i_MainLayer.i_Back.i_TintLayer, 0xFF3300); 
						break;
					case 4:
						Colors.ApplyColor(m_BuffCharge.i_Offset.i_PosLayer.i_ScaleLayer.i_MainLayer.i_Back.i_TintLayer, 0xFF0000);
						Chat.SignalShowFIFOMessage.Emit(m_UtaType + "-Uta enraged! BURN OR DIE!");
						break;
				}
				return;
			}
		}
		
		m_SisterlyBonds.text = "?";
	}
	
	private function SlotStatChanged()
	{
		var maxHP:Number = Math.max(0, m_Uta.GetStat(_global.Enums.Stat.e_Life, 2));
		var currentHP:Number = m_Uta.GetStat(_global.Enums.Stat.e_Health, 2);
		var percHP = 100 * currentHP / maxHP;
		
		m_HealthBar.m_Background._xscale = percHP;
		m_HealthBar.m_Text.text = currentHP + " / " + maxHP + " ("+Math.ceil(percHP)+"%)";
		
		var shieldHP:Number = m_Uta.GetStat(_global.Enums.Stat.e_CurrentPinkShield, 2)
			+ m_Uta.GetStat(_global.Enums.Stat.e_CurrentBlueShield, 2)
			+ m_Uta.GetStat(_global.Enums.Stat.e_CurrentRedShield, 2);
		var maxShieldHP:Number = m_Uta.GetStat(_global.Enums.Stat.e_AbsolutePinkShield, 2)
			+ m_Uta.GetStat(_global.Enums.Stat.e_AbsoluteBlueShield, 2)
			+ m_Uta.GetStat(_global.Enums.Stat.e_AbsoluteRedShield, 2);
		var percShieldHP = 100 * shieldHP / maxShieldHP;
		
		m_ShieldBar.m_Background._xscale = percShieldHP;
		
		if (shieldHP > 0)
			m_ShieldBar.m_Text.text = shieldHP + " / " + maxShieldHP + " (" + Math.ceil(percShieldHP) + "%)";
		else
			m_ShieldBar.m_Text.text = m_UtaType + "-Uta";
	}
	
	
	// GUI EDIT MODE
	private function SlotSetGUIEditMode(edit:Boolean)
	{	
		edit = edit && (m_Character.GetPlayfieldID() == 6892);
		
		m_EditModeMask._visible = edit;
		if (edit)
		{
			LayoutEditModeMask();
			this.onMouseWheel = function( delta:Number )
			{
				var scaleDV:DistributedValue = DistributedValue.Create(m_UtaType + "utaScale");
				var scale:Number = scaleDV.GetValue();
				scale = Math.min(200, Math.max(50, scale));
				scaleDV.SetValue(scale + delta);
				
				this._yscale = this._xscale = scale;
			}
		}
		else
		{
			this.onMouseWheel = function() { }
			_visible = (m_Uta != null);
		}
	}

	private function SlotEditMaskPressed()
	{
		var scale:Number = 1; // m_ScaleMonitor.GetValue() / 100;
		this.startDrag(false, 0 - (m_EditModeMask._x * scale), 0 - (m_EditModeMask._y * scale), Stage.width - ((m_EditModeMask._width + m_EditModeMask._x) * scale - (2*scale)), Stage.height - ((m_EditModeMask._height + m_EditModeMask._y) * scale - (2*scale)));
	}

	private function SlotEditMaskReleased()
	{
		if (!m_EditModeMask._visible)
			return;
		
		this.stopDrag();
		
		var X:DistributedValue = DistributedValue.Create( m_UtaType + "utaX" );
		var Y:DistributedValue = DistributedValue.Create( m_UtaType + "utaY" );	
		
		X.SetValue(this._x);
		Y.SetValue(this._y);	

	}

	private function LayoutEditModeMask()
	{
		_visible = true;
			
		m_EditModeMask._x = - 5;
		m_EditModeMask._y = - 5;
		m_EditModeMask._width = m_Border._width + 10;
		m_EditModeMask._height = m_Border._height + 10;
	}
}