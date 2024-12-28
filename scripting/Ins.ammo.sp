#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <csgocolors_fix>


bool g_bInfAmmoAll = false;
bool g_bInfAmmo[MAXPLAYERS + 1] = {false, ...};
bool g_bInfAmmoHooked = false;


public Plugin myinfo =
{
	name 		= "ammo",
	author 		= "Ins",
	description	= "",
	version 	= "1.1",
	url 		= ""
};

public void OnPluginStart()
{
	RegAdminCmd("sm_ammo", Command_InfAmmo, ADMFLAG_GENERIC, "sm_ammo <#userid|name> <0|1>");
	RegConsoleCmd("sm_zammo", Command_Zammo,"sm_zammo");
}


public Action Command_InfAmmo(int client, int argc)
{
	if(argc < 2)
	{
		ReplyToCommand(client,"[Weapons] Usage: sm_ammo <#userid|name> <0|1>");
		return Plugin_Handled;
	}

	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	int value = -1;
	char arg2[20];
	GetCmdArg(2, arg2, sizeof(arg2));

	if(StringToIntEx(arg2, value) == 0)
	{
		ReplyToCommand(client,"[Weapons] Invalid Value");
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

public Action Command_Zammo(int client,int args)
{
	if(client == 0)
	{
		LogMessage("请使用客户端来使用此命令");
		return Plugin_Handled;
	}
	char name[32];
	GetClientName(client,name,sizeof(name));
	int userid;
	client = GetClientOfUserId(userid);

	ServerCommand("sm_ammo %d 1",client);
	CPrintToChat(client,"[\x04Weapons\x01] 无限弹药已开启");
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