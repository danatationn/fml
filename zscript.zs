version "2.30"

class FMLHandler : EventHandler {
	override void PlayerSpawned(PlayerEvent e) {
		let player = players[e.playernumber];
		let mo = player.mo;
		if (!mo.FindInventory("FMLInventory")) mo.GiveInventory("FMLInventory", 1);
	}
}

class FMLInventory : Inventory {
	float pitch;
	uint16 oldWeaponState;

	Default {
		+INVENTORY.AUTOACTIVATE;
	}
	
	override void Tick() {
		let player = owner.player;
		let mo = player.mo;
		
		if (!mo.GetCVar("fml_enabled")) return;
		// basically if the player has mouselook on, disable the mod
		if (GetCVar("autoaim") < 35 && (GetCVar("m_pitch") > 0 && GetCVar("freelook"))) return;

		// force autoaim on weapons that disable this
		// shouldn't be used with grenades or things that actually need this flag
		if (player.readyweapon && mo.GetCVar("fml_force_autoaim"))
			player.readyweapon.A_ChangeFlag("WEAPON.NOAUTOAIM", false);

		// we want to reset the pitch ONLY after the player has finished shooting.
		// for this we need to seek the last tic the player was shooting and the next tic where the player isn't
		if (!(oldWeaponState & WF_WEAPONREADY) && player.weaponState & WF_WEAPONREADY && !mo.GetCVar("fml_during_shooting"))
			mo.A_SetPitch(pitch, SPF_INTERPOLATE);

		// or do it more aggresively
		if (!(player.weaponState & WF_WEAPONREADY) && mo.GetCVar("fml_during_shooting"))
			// setting it to 0 insures that your screen gets centered in some cases
			mo.A_SetPitch(0, SPF_INTERPOLATE);
		
		if (player.weaponState & WF_WEAPONREADY)
			pitch = mo.pitch;
		
		oldWeaponState = player.weaponState;
	}
}