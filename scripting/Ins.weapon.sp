#include <sourcemod>
#include <cstrike>
#include <smutils>

int g_iHEAmount[MAXPLAYERS+1];

bool g_bInfAmmoAll = false;
bool g_bInfAmmo[MAXPLAYERS + 1] = {false, ...};
bool g_bInfAmmoHooked = false;

public Plugin myinfo =
{
	name = "Weapon",
	author = "Ins",
	description = "Weapon",
	version = "1.0.5",
	url = "https://space.bilibili.com/442385547"
}

public void OnPluginStart()
{
	RegAdminCmd("sm_ammo", Command_InfAmmo, ADMFLAG_GENERIC, "sm_ammo <#userid|name> <0|1>");

	RegConsoleCmd("sm_ak", Command_ak, "Spawns a ak47");
	RegConsoleCmd("sm_ak47", Command_ak, "Spawns a ak47");
	RegConsoleCmd("sm_aug", Command_aug, "Spawns a aug");
	RegConsoleCmd("sm_famas", Command_famas, "Spawns a famas");
	RegConsoleCmd("sm_m4", Command_m4a1, "Spawns a m4a1");
	RegConsoleCmd("sm_m4a1", Command_m4a1, "Spawns a m4a1");
	RegConsoleCmd("sm_m4s", Command_m4a1s, "Spawns a m4a1-s");
	RegConsoleCmd("sm_m4a1s", Command_m4a1s, "Spawns a m4a1-s");
	RegConsoleCmd("sm_sg556", Command_sg556, "Spawns a sg556");
	RegConsoleCmd("sm_sg553", Command_sg556, "Spawns a sg556");

	RegConsoleCmd("sm_nova", Command_nova, "Spawns a nova");
	RegConsoleCmd("sm_xm", Command_xm1014, "Spawns a xm");
	RegConsoleCmd("sm_xm1014", Command_xm1014, "Spawns a xm");

	RegConsoleCmd("sm_scar", Command_scar, "Spawns a scar20");
	RegConsoleCmd("sm_awp", Command_awp, "Spawns a awp");
	RegConsoleCmd("sm_ssg", Command_ssg08, "Spawns a ssg08");
	RegConsoleCmd("sm_ssg08", Command_ssg08, "Spawns a ssg08");

	RegConsoleCmd("sm_bizon", Command_bizon, "Spawns a bizon");
	RegConsoleCmd("sm_pp", Command_bizon, "Spawns a bizon");
	RegConsoleCmd("sm_p90", Command_p90, "Spawns a p90");
	RegConsoleCmd("sm_mac10", Command_mac10, "Spawns a mac10");
	RegConsoleCmd("sm_mp9", Command_mp9, "Spawns a mp9");
	RegConsoleCmd("sm_mp7", Command_mp7, "Spawns a mp7");
	RegConsoleCmd("sm_mp5", Command_mp5, "Spawns a mp5sd");
	RegConsoleCmd("sm_ump", Command_ump45, "Spawns a ump45");
	RegConsoleCmd("sm_ump45", Command_ump45, "Spawns a ump45");

	RegConsoleCmd("sm_m249", Command_m249, "Spawns a m249");
	RegConsoleCmd("sm_negev", Command_negev, "Spawns a negev");

	RegConsoleCmd("sm_usp", Command_usp, "Spawns a usp");
	RegConsoleCmd("sm_glock", Command_glock, "Spawns a glock");
	RegConsoleCmd("sm_p250", Command_p250, "Spawns a p250");
	RegConsoleCmd("sm_deagle", Command_deag, "Spawns a deagle");
	RegConsoleCmd("sm_57", Command_57, "Spawns a fiveseven");
	RegConsoleCmd("sm_cz", Command_cz, "Spawns a cz");
	RegConsoleCmd("sm_r8", Command_r8, "Spawns a r8");
	RegConsoleCmd("sm_elite", Command_elites, "Spawns a elite");
	RegConsoleCmd("sm_tec9", Command_tec9, "Spawns a tec9");
	RegConsoleCmd("sm_p2000", Command_p2k, "Spawns a p2000");

	RegConsoleCmd("sm_kev", Command_armor, "Spawns a armor");
	RegConsoleCmd("sm_kevlar", Command_armor, "Spawns a armor");
	RegConsoleCmd("sm_he", Command_he, "Spawns a he grenade");
}

public Action Command_ak(int client, int args)
{
	if(!ClientIsValid(client) || !ClientIsAlive(client)) return Plugin_Handled;

	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	if(weapon != -1)
	{
		RemoveWeapon(client,weapon);
		GivePlayerItem(client,"weapon_ak47");
	}
	else
	{
		GivePlayerItem(client,"weapon_ak47");    
	}
	return Plugin_Handled;
}
public Action Command_aug(int client, int args)
{
	if(!ClientIsValid(client) || !ClientIsAlive(client)) return Plugin_Handled;

	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	if(weapon != -1)
	{
		RemoveWeapon(client,weapon);
		GivePlayerItem(client,"weapon_aug");
	}
	else
	{
		GivePlayerItem(client,"weapon_aug");
	}
	return Plugin_Handled;
}
public Action Command_famas(int client, int args)
{
	if(!ClientIsValid(client) || !ClientIsAlive(client)) return Plugin_Handled;

	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	if(weapon != -1)
	{
		RemoveWeapon(client,weapon);
		GivePlayerItem(client,"weapon_famas");
	}
	else
	{
		GivePlayerItem(client,"weapon_famas");
	}
	return Plugin_Handled;
}
public Action Command_m4a1(int client, int args)
{
	if(!ClientIsValid(client) || !ClientIsAlive(client)) return Plugin_Handled;

	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	if(weapon != -1)
	{
		RemoveWeapon(client,weapon);
		GivePlayerItem(client,"weapon_m4a1");
	}
	else
	{
		GivePlayerItem(client,"weapon_m4a1");
	}
	return Plugin_Handled;
}
public Action Command_m4a1s(int client, int args)
{
	if(!ClientIsValid(client) || !ClientIsAlive(client)) return Plugin_Handled;

	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	if(weapon != -1)
	{
		RemoveWeapon(client,weapon);
		GivePlayerItem(client,"weapon_m4a1_silencer");
	}
	else
	{
		GivePlayerItem(client,"weapon_m4a1_silencer");
	}
	return Plugin_Handled;
}
public Action Command_sg556(int client, int args)
{
	if(!ClientIsValid(client) || !ClientIsAlive(client)) return Plugin_Handled;

	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	if(weapon != -1)
	{
		RemoveWeapon(client,weapon);
		GivePlayerItem(client,"weapon_sg556");
	}
	else
	{
		GivePlayerItem(client,"weapon_sg556");
	}
	return Plugin_Handled;
}
public Action Command_nova(int client, int args)
{
	if(!ClientIsValid(client) || !ClientIsAlive(client)) return Plugin_Handled;

	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	if(weapon != -1)
	{
		RemoveWeapon(client,weapon);
		GivePlayerItem(client,"weapon_nova");
	}
	else
	{
		GivePlayerItem(client,"weapon_nova");
	}
	return Plugin_Handled;
}
public Action Command_xm1014(int client, int args)
{
	if(!ClientIsValid(client) || !ClientIsAlive(client)) return Plugin_Handled;

	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	if(weapon != -1)
	{
		RemoveWeapon(client,weapon);
		GivePlayerItem(client,"weapon_xm1014");
	}
	else
	{
		GivePlayerItem(client,"weapon_xm1014");
	}
	return Plugin_Handled;
}
public Action Command_scar(int client, int args)
{
	if(!ClientIsValid(client) || !ClientIsAlive(client)) return Plugin_Handled;

	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	if(weapon != -1)
	{
		RemoveWeapon(client,weapon);
		GivePlayerItem(client,"weapon_scar20");
	}
	else
	{
		GivePlayerItem(client,"weapon_scar20");
	}
	return Plugin_Handled;
}
public Action Command_awp(int client, int args)
{
	if(!ClientIsValid(client) || !ClientIsAlive(client)) return Plugin_Handled;

	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	if(weapon != -1)
	{
		RemoveWeapon(client,weapon);
		GivePlayerItem(client,"weapon_awp");
	}
	else
	{
		GivePlayerItem(client,"weapon_awp");
	}
	return Plugin_Handled;
}
public Action Command_ssg08(int client, int args)
{
	if(!ClientIsValid(client) || !ClientIsAlive(client)) return Plugin_Handled;

	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	if(weapon != -1)
	{
		RemoveWeapon(client,weapon);
		GivePlayerItem(client,"weapon_ssg08");
	}
	else
	{
		GivePlayerItem(client,"weapon_ssg08");
	}
	GivePlayerItem(client,"weapon_ssg08");
	return Plugin_Handled;
}
public Action Command_bizon(int client, int args)
{
	if(!ClientIsValid(client) || !ClientIsAlive(client)) return Plugin_Handled;

	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	if(weapon != -1)
	{
		RemoveWeapon(client,weapon);
		GivePlayerItem(client,"weapon_bizon");
	}
	else
	{
		GivePlayerItem(client,"weapon_bizon");
	}
	return Plugin_Handled;
}
public Action Command_p90(int client, int args)
{
	if(!ClientIsValid(client) || !ClientIsAlive(client)) return Plugin_Handled;

	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	if(weapon != -1)
	{
		RemoveWeapon(client,weapon);
		GivePlayerItem(client,"weapon_p90");
	}
	else
	{
		GivePlayerItem(client,"weapon_p90");
	}
	return Plugin_Handled;
}
public Action Command_mac10(int client, int args)
{
	if(!ClientIsValid(client) || !ClientIsAlive(client)) return Plugin_Handled;

	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	if(weapon != -1)
	{
		RemoveWeapon(client,weapon);
		GivePlayerItem(client,"weapon_mac10");
	}
	else
	{
		GivePlayerItem(client,"weapon_mac10");
	}
	return Plugin_Handled;
}
public Action Command_mp9(int client, int args)
{
	if(!ClientIsValid(client) || !ClientIsAlive(client)) return Plugin_Handled;

	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	if(weapon != -1)
	{
		RemoveWeapon(client,weapon);
		GivePlayerItem(client,"weapon_mp9");
		int mp9 = GetPlayerWeaponEntity(client, "weapon_mp9");
		SetEntProp(weapon, Prop_Data, "m_iClip1", 100);
		SetWeaponClip(mp9, 100);
	}
	else
	{
		GivePlayerItem(client,"weapon_mp9");
	}
	return Plugin_Handled;
}
public Action Command_mp7(int client, int args)
{
	if(!ClientIsValid(client) || !ClientIsAlive(client)) return Plugin_Handled;
	
	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	if(weapon != -1)
	{
		RemoveWeapon(client,weapon);
		GivePlayerItem(client,"weapon_mp7");
	}
	else
	{
		GivePlayerItem(client,"weapon_mp7");
	}
	return Plugin_Handled;
}
public Action Command_mp5(int client, int args)
{
	if(!ClientIsValid(client) || !ClientIsAlive(client)) return Plugin_Handled;

	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	if(weapon != -1)
	{
		RemoveWeapon(client,weapon);
		GivePlayerItem(client,"weapon_mp5");
	}
	else
	{
		GivePlayerItem(client,"weapon_mp5");
	}
	return Plugin_Handled;
}
public Action Command_ump45(int client, int args)
{
	if(!ClientIsValid(client) || !ClientIsAlive(client)) return Plugin_Handled;

	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	if(weapon != -1)
	{
		RemoveWeapon(client,weapon);
		GivePlayerItem(client,"weapon_ump45");
	}
	else
	{
		GivePlayerItem(client,"weapon_ump45");
	}
	return Plugin_Handled;
}
public Action Command_m249(int client, int args)
{
	if(!ClientIsValid(client) || !ClientIsAlive(client)) return Plugin_Handled;

	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	if(weapon != -1)
	{
		RemoveWeapon(client,weapon);
		GivePlayerItem(client,"weapon_m249");
	}
	else
	{
		GivePlayerItem(client,"weapon_m249");
	}
	return Plugin_Handled;
}
public Action Command_negev(int client, int args)
{
	if(!ClientIsValid(client) || !ClientIsAlive(client)) return Plugin_Handled;

	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	if(weapon != -1)
	{
		RemoveWeapon(client,weapon);
		GivePlayerItem(client,"weapon_negev");
	}
	else
	{
		GivePlayerItem(client,"weapon_negev");
	}
	return Plugin_Handled;
}
public Action Command_usp(int client, int args)
{
	if(!ClientIsValid(client) || !ClientIsAlive(client)) return Plugin_Handled;

	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	if(weapon != -1)
	{
		RemoveWeapon(client,weapon);
		GivePlayerItem(client,"weapon_usp_silencer");
	}
	else
	{
		GivePlayerItem(client,"weapon_usp_silencer");
	}
	return Plugin_Handled;
}
public Action Command_p250(int client, int args)
{
	if(!ClientIsValid(client) || !ClientIsAlive(client)) return Plugin_Handled;
	
	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	if(weapon != -1)
	{
		RemoveWeapon(client,weapon);
		GivePlayerItem(client,"weapon_p250");
	}
	else
	{
		GivePlayerItem(client,"weapon_p250");
	}
	return Plugin_Handled;
}
public Action Command_glock(int client, int args)
{
	if(!ClientIsValid(client) || !ClientIsAlive(client)) return Plugin_Handled;

	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	if(weapon != -1)
	{
		RemoveWeapon(client,weapon);
		GivePlayerItem(client,"weapon_glock");
	}
	else
	{
		GivePlayerItem(client,"weapon_glock");
	}
	return Plugin_Handled;
}
public Action Command_deag(int client, int args)
{
	if(!ClientIsValid(client) || !ClientIsAlive(client)) return Plugin_Handled;

	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	if(weapon != -1)
	{
		RemoveWeapon(client,weapon);
		GivePlayerItem(client,"weapon_deagle");
	}
	else
	{
		GivePlayerItem(client,"weapon_deagle");
	}
	return Plugin_Handled;
}
public Action Command_cz(int client, int args)
{
	if(!ClientIsValid(client) || !ClientIsAlive(client)) return Plugin_Handled;

	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	if(weapon != -1)
	{
		RemoveWeapon(client,weapon);
		GivePlayerItem(client,"weapon_cz75a");
	}
	else
	{
		GivePlayerItem(client,"weapon_cz75a");
	}
	return Plugin_Handled;
}
public Action Command_r8(int client, int args)
{
	if(!ClientIsValid(client) || !ClientIsAlive(client)) return Plugin_Handled;

	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	if(weapon != -1)
	{
		RemoveWeapon(client,weapon);
		GivePlayerItem(client,"weapon_revolver");
	}
	else
	{
		GivePlayerItem(client,"weapon_revolver");
	}
	return Plugin_Handled;
}
public Action Command_57(int client, int args)
{
	if(!ClientIsValid(client) || !ClientIsAlive(client)) return Plugin_Handled;

	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	if(weapon != -1)
	{
		RemoveWeapon(client,weapon);
		GivePlayerItem(client,"weapon_fiveseven");
	}
	else
	{
		GivePlayerItem(client,"weapon_fiveseven");
	}
	return Plugin_Handled;
}
public Action Command_elites(int client, int args)
{
	if(!ClientIsValid(client) || !ClientIsAlive(client)) return Plugin_Handled;

	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	if(weapon != -1)
	{
		RemoveWeapon(client,weapon);
		GivePlayerItem(client,"weapon_elite");
	}
	else
	{
		GivePlayerItem(client,"weapon_elite");
	}
	return Plugin_Handled;
}
public Action Command_tec9(int client, int args)
{
	if(!ClientIsValid(client) || !ClientIsAlive(client)) return Plugin_Handled;

	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	if(weapon != -1)
	{
		RemoveWeapon(client,weapon);
		GivePlayerItem(client,"weapon_tec9");
	}
	else
	{
		GivePlayerItem(client,"weapon_tec9");
	}
	return Plugin_Handled;
}
public Action Command_p2k(int client, int args)
{
	if(!ClientIsValid(client) || !ClientIsAlive(client)) return Plugin_Handled;

	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	if(weapon != -1)
	{
		RemoveWeapon(client,weapon);
		GivePlayerItem(client,"weapon_hkp2000");
	}
	else
	{
		GivePlayerItem(client,"weapon_hkp2000");
	}
	return Plugin_Handled;
}

public Action Command_armor(int client, int args)
{
	if(!ClientIsValid(client) || !ClientIsAlive(client)) return Plugin_Handled;

	SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
	SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
	return Plugin_Handled;
}

public Action Command_he(int client, int args)
{
	if(!ClientIsValid(client) || !ClientIsAlive(client)) return Plugin_Handled;

	HEGrenade(client);
	g_iHEAmount[client] += 1;
	return Plugin_Handled;
}

public void HEGrenade(int client)
{
	int offset2 = FindDataMapInfo(client, "m_iAmmo") + (4*14);
	int current2 = GetEntData(client, offset2, 4);

	if (current2 == 0) GivePlayerItem(client, "weapon_hegrenade");
	else SetEntData(client,offset2,current2+1);
}

public Action Command_InfAmmo(int client, int argc)
{
	if(argc < 2)
	{
		ReplyToCommand(client,"[\x04Weapons\x01] Usage: sm_ammo <#userid|name> <0|1>");
		return Plugin_Handled;
	}

	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	int value = -1;
	char arg2[20];
	GetCmdArg(2, arg2, sizeof(arg2));

	if(StringToIntEx(arg2, value) == 0)
	{
		ReplyToCommand(client,"[\x04Weapons\x01] Invalid Value");
		return Plugin_Handled;
	}

	char target_name[MAX_TARGET_LENGTH];

	if(StrEqual(arg, "@all", false))
	{
		target_name = "全体玩家";
		g_bInfAmmoAll = value ? true : false;

		if(!g_bInfAmmoAll)
		{
			for(int i = 0; i < MAXPLAYERS; i++)
			g_bInfAmmo[i] = false;
		}
	}
	else
	{
		int target_list[MAXPLAYERS];
		int target_count;
		bool tn_is_ml;

		if((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		for(int i = 0; i < target_count; i++)
		{
			g_bInfAmmo[target_list[i]] = value ? true : false;
		}
	}

	ShowActivity2(client, "[\x04Weapons\x01] \x04", "%s\x01 的无限弹药已 \x04%s", target_name ,(value ? "开启" : "关闭"));
	LogAction(client, -1, "%s 的无限弹药已 %s", target_name , (value ? "开启" : "关闭"));

	if(g_bInfAmmoAll)
	{
		if(!g_bInfAmmoHooked)
		{
			HookEvent("weapon_fire", Event_WeaponFire);
			g_bInfAmmoHooked = true;
		}

		return Plugin_Handled;
	}

	for(int i = 0; i < MAXPLAYERS; i++)
	{
		if(g_bInfAmmo[i])
		{
			if(!g_bInfAmmoHooked)
			{
				HookEvent("weapon_fire", Event_WeaponFire);
				g_bInfAmmoHooked = true;
			}

			return Plugin_Handled;
		}
	}

	if(g_bInfAmmoHooked)
	{
		UnhookEvent("weapon_fire", Event_WeaponFire);
		g_bInfAmmoHooked = false;
	}

	return Plugin_Handled;
}

public void Event_WeaponFire(Handle hEvent, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(!g_bInfAmmoAll && !g_bInfAmmo[client])
	return;

	int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", 0);
	if(IsValidEntity(weapon))
	{
		if(weapon == GetPlayerWeaponSlot(client, 0) || weapon == GetPlayerWeaponSlot(client, 1))
		{
			if(GetEntProp(weapon, Prop_Send, "m_iState", 4, 0) == 2 && GetEntProp(weapon, Prop_Send, "m_iClip1", 4, 0))
			{
				int toAdd = 1;
				char weaponClassname[128];
				GetEntityClassname(weapon, weaponClassname, sizeof(weaponClassname));

				if(StrEqual(weaponClassname, "weapon_glock", true) || StrEqual(weaponClassname, "weapon_famas", true))
				{
					if(GetEntProp(weapon, Prop_Send, "m_bBurstMode"))
					{
						switch (GetEntProp(weapon, Prop_Send, "m_iClip1"))
						{
							case 1:
							{
								toAdd = 1;
							}
							case 2:
							{
								toAdd = 2;
							}
							default:
							{
								toAdd = 3;
							}
						}
					}
				}
				SetEntProp(weapon, Prop_Send, "m_iClip1", GetEntProp(weapon, Prop_Send, "m_iClip1", 4, 0) + toAdd, 4, 0);
			}
		}
	}
	return;
}