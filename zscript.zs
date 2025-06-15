version "2.30"

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

			if (mo.GetCVar("autoaim") < 35 && (mo.GetCVar("m_pitch") > 0 && mo.GetCVar("freelook"))) return;
			if (!mo.GetCVar("fml_force_autoaim")) return;
			
			vector3 weapPos = (
				weap.pos.x,
				weap.pos.y,
				weap.pos.z
			);

			vector3 playerPos = (
				mo.pos.x,
				mo.pos.y,
				mo.pos.z + player.viewheight
			);
			weap.SetXYZ((
				playerPos.x,
				playerPos.y,
				playerPos.z
			));
			
			FTranslatedLineTarget pLineTarget;
			double pitch = weap.AimLineAttack(mo.angle, 8192, pLineTarget, 0, ALF_NOWEAPONCHECK);
			Actor target = pLineTarget.linetarget;

			weap.SetXYZ((
				weapPos.x,
				weapPos.y,
				weapPos.z
			));
			
			if (pitch && target) {
				vector3 targetPos = (
					target.pos.x,
					target.pos.y,
					target.pos.z + (target.height / 2)
				);
				vector3 diff = targetPos - playerPos;
			
				double flatDist = (diff.x, diff.y).Length();
				double properPitch = -atan2(diff.z, flatDist);
				double speed = e.Thing.Vel.Length();
			
				e.Thing.Vel.Z = -sin(properPitch) * speed;
			}
		}
	}
}

class FMLInventory : Inventory {
	float pitch;
	uint16 oldWeaponState;
	Array<Weapon> flaggedWeapons;

	Default {
		+INVENTORY.AUTOACTIVATE;
	}
	
	override void Tick() {
		PlayerInfo player = owner.player;
		PlayerPawn mo = player.mo;
		Weapon weap = player.readyweapon;
		double maxPitch = mo.GetCVar("fml_max_pitch");
		
		if (!mo.GetCVar("fml_enabled")) return;
		if (GetCVar("autoaim") < 35 && (GetCVar("m_pitch") > 0 && GetCVar("freelook"))) return;

		// we want to reset the pitch ONLY after the player has finished shooting
		if (!(oldWeaponState & WF_WEAPONREADY) && player.weaponState & WF_WEAPONREADY && !mo.GetCVar("fml_during_shooting"))
			mo.A_SetPitch(pitch, SPF_INTERPOLATE);

		if (player.weaponState & WF_WEAPONREADY)
			pitch = mo.pitch;

		if (mo.pitch > maxPitch)
			mo.A_SetPitch(maxPitch, SPF_INTERPOLATE);
		if (mo.pitch < -maxPitch)
			mo.A_SetPitch(-maxPitch, SPF_INTERPOLATE);
		
		oldWeaponState = player.weaponState;
		
		// keep track of the weapons that disable autoaim
		if (!weap) return;
		
		if (weap.bNOAUTOAIM == true && flaggedWeapons.Find(weap) == flaggedWeapons.Size())
			flaggedWeapons.Push(weap);

		if (mo.GetCVar("fml_force_autoaim"))
			weap.bNOAUTOAIM = false;
		else if (flaggedWeapons.Find(weap) != flaggedWeapons.Size())
			weap.bNOAUTOAIM = true;
	}
}