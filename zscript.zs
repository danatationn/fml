version "4.13.0"

class FMLHandler : EventHandler {
	override void PlayerSpawned(PlayerEvent e) {
		let player = players[e.playernumber];
		let mo = player.mo;
		if (!mo.FindInventory("FMLInventory")) mo.GiveInventory("FMLInventory", 1);
	}
	
	override void WorldThingSpawned(WorldEvent e) {
		if (e.Thing && e.Thing.target && e.Thing.target.player && e.Thing.target.player.readyweapon) {
			PlayerInfo player = e.Thing.target.player;
			PlayerPawn mo = player.mo;
			Weapon weap = player.readyweapon;

			if (mo.GetCVar("fml_force_autoaim") == 0)
				return;

			// the weapons pos is at 0 0 0
			vector3 weapPos = (weap.pos.x, weap.pos.y, weap.pos.z);
			vector3 playerPos = (mo.pos.x, mo.pos.y, mo.pos.z + player.viewheight);
			weap.SetXYZ((playerPos.x, playerPos.y, playerPos.z));
			
			FTranslatedLineTarget pLineTarget;
			// even though we are supplying the players angle it's still using the weapon's pos
			double pitch = weap.AimLineAttack(mo.angle, 8192, pLineTarget, 0, ALF_NOWEAPONCHECK);
			Actor target = pLineTarget.linetarget;
			
			if (pitch)
				e.Thing.Vel.Z = -sin(pitch) * e.Thing.Vel.Length();
			
			weap.SetXYZ((weapPos.x, weapPos.y, weapPos.z));
		}
	}
}

class FMLInventory : Inventory {
	Array<Weapon> flaggedWeapons;

	Default {
		+INVENTORY.UNDROPPABLE;
		+INVENTORY.PERSISTENTPOWER;
	}
	
	override void DoEffect() {
		PlayerInfo player = owner.player;
		PlayerPawn mo = player.mo;
		Weapon weap = player.readyweapon;
		double maxPitch = mo.GetCVar("fml_max_pitch");
		
		// keep track of the weapons that disable autoaim
		if (!weap)
			return;
		
		if (weap.bNOAUTOAIM == true && flaggedWeapons.Find(weap) == flaggedWeapons.Size())
			flaggedWeapons.Push(weap);

		if (mo.GetCVar("fml_force_autoaim"))
			weap.bNOAUTOAIM = false;
		else if (flaggedWeapons.Find(weap) != flaggedWeapons.Size())
			weap.bNOAUTOAIM = true;
		
		if (!mo.GetCVar("fml_enabled"))
			return;
		if (GetCVar("autoaim") == 0 && (GetCVar("m_pitch") > 0 && GetCVar("freelook")))
			return;

		if (player.weaponState & WF_WEAPONREADY)
			mo.A_SetPitch(0, SPF_INTERPOLATE);

		if (mo.pitch > maxPitch)
			mo.A_SetPitch(maxPitch, SPF_INTERPOLATE);
		if (mo.pitch < -maxPitch)
			mo.A_SetPitch(-maxPitch, SPF_INTERPOLATE);
	}
}