version "4.11"

class FMLHandler : EventHandler {
	override void PlayerSpawned(PlayerEvent e) {
		let player = players[e.playernumber];
		let mo = player.mo;
		if (!mo.FindInventory("FMLInventory")) mo.GiveInventory("FMLInventory", 1);
	}
}

class FMLInventory : Inventory {
	float pitch;
	bool isattacking;
	int tics;

	Default {
		+INVENTORY.AUTOACTIVATE;
	}
	
	bool GetFreelook() {
		return GetCVar("autoaim") < 35 && (GetCVar("m_pitch") > 0 && GetCVar("freelook"));
	}
	
	override void Tick() {
		let player = owner.player;
		let mo = player.mo;
		
		if (!mo.GetCVar("fml_enabled")) return;
		if (mo.GetCVar("fml_auto_disable") && GetFreelook()) return;

		if (player.WeaponState & WF_WEAPONREADY) {
			if (isattacking) {
				if (mo.GetCVar("fml_reset_pitch")) {
					mo.pitch = 0;
				} else {
					mo.pitch = pitch;				
				}
				isattacking = false;
			} else {
				pitch = mo.pitch;
			}
		} else {
			isattacking = true;
		}
	
	
	
	}
}