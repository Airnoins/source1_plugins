#pragma semicolon 1
#pragma newdecls required


//////////////////////////////
//    PLUGIN DEFINITION     //
//////////////////////////////
#define PLUGIN_NAME         "Ins.leader"
#define PLUGIN_AUTHOR       "Ins"
#define PLUGIN_DESCRIPTION  "leader"
#define PLUGIN_VERSION      "1.3"
#define PLUGIN_URL          "https://space.bilibili.com/442385547"

public Plugin myinfo =
{
	name 		= PLUGIN_NAME,
	author 		= PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version 	= PLUGIN_VERSION,
	url 		= PLUGIN_URL
};


//////////////////////////////
//          INCLUDES        //
//////////////////////////////
#include <sourcemod>
#include <smutils>
#include <sdkhooks>

// Laser
#include <lasers> //太懒直接引入


//////////////////////////////
//          DEFINE          //
//////////////////////////////

#define EF_BONEMERGE                (1 << 0)

bool PlayerLeader[MAXPLAYERS+1];
bool PlayerLeaderLarse[MAXPLAYERS+1];

int g_iPlayerModelsIndex[MAXPLAYERS + 1] = { -1, ... };
int g_iPlayerModels[MAXPLAYERS + 1] = {INVALID_ENT_REFERENCE, ... };
int LeaderMakerEntity[MAXPLAYERS + 1][3];
int LeaderMakerCount[MAXPLAYERS+1];
int LeaderMakerMax[MAXPLAYERS+1];

char LeaderMarkVMT[512] = "materials/maoling/ze/defend_fys_mult1.vmt";
char LeaderMarkVTF[512] = "materials/maoling/ze/defend_fys_mult1.vtf";

float g_pos[MAXPLAYERS+1][3];

ConVar CVAR_SV_FORCE_TRANSMIT_PLAYERS = null;

//////////////////////////////
//          Forward         //
//////////////////////////////

public void OnPluginStart()
{
	RegConsoleCmd("sm_leader", Command_Leader, "open leader function");

	Laser_OnPluginStart();
	SMUtils_SetChatPrefix("[\x0DIns.leader\x01]");
	SMUtils_SetChatSpaces("   ");
	SMUtils_SetChatConSnd(false);
	SMUtils_SetTextDest(HUD_PRINTCENTER);

	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);

	AddCommandListener(PlayerPing, "player_ping");

	CVAR_SV_FORCE_TRANSMIT_PLAYERS = FindConVar("sv_force_transmit_players");
}

public void OnClientPutInServer(int client)
{
	PlayerLeader[client] = false;
	PlayerLeaderLarse[client] = false;
	LeaderMakerCount[client] = 0;
	LeaderMakerMax[client] = 0;
	Laser_OnClientPutInServer(client);
}

public void OnMapStart()
{
	Laser_OnMapStart();
	ServerCommand("sv_disable_immunity_alpha 1");

	//Maker vmt&vtf
	PrecacheGeneric(LeaderMarkVMT, true);
	PrecacheGeneric(LeaderMarkVTF, true);
	AddFileToDownloadsTable(LeaderMarkVMT);
	AddFileToDownloadsTable(LeaderMarkVTF);
}

//////////////////////////////
//          EVENT           //
//////////////////////////////

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(PlayerLeader[client] == true)
	{
		RemoveSkin(client);
		PerformGlow(client);
	}
}

//////////////////////////////
//          CMD             //
//////////////////////////////

public Action Command_Leader(int client, int args)
{
	if(ClientIsValid(client) && ClientIsAlive(client))
	{
		if(PlayerLeader[client] == true)
		{
			RemoveLeader(client);
			Chat(client, "Leader功能关闭");
		}
		else
		{
			PerformLeader(client);
			Chat(client, "Leader功能开启");
		}
	}
	return Plugin_Handled;
}

public void PerformLeader(int client)
{
	PlayerLeader[client] = true;
	PerformGlow(client);
}

public void RemoveLeader(int client)
{
	PlayerLeader[client] = false;
	RemoveSkin(client);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(ClientIsValid(client) && ClientIsAlive(client))
	{
		if(buttons & IN_RELOAD && PlayerLeader[client] == true && PlayerLeaderLarse[client] == false)
		{
			Command_LaserOn(client, 0);
			PlayerLeaderLarse[client] = true;
		}
		else if(!(buttons & IN_RELOAD) && PlayerLeaderLarse[client] == true)
		{
			Command_LaserOff(client, 0);
			PlayerLeaderLarse[client] = false;
		}

		if(buttons & IN_ATTACK2 && PlayerLeader[client] == true)
		{
			RemoveMaker(LeaderMakerEntity[client][0]);
			RemoveMaker(LeaderMakerEntity[client][1]);
			RemoveMaker(LeaderMakerEntity[client][2]);
		}
	}
	return Plugin_Continue;
}

//////////////////////////////
//          Glow            //
//////////////////////////////

public void PerformGlow(int client)
{
	if(g_iPlayerModelsIndex[client] == -1)
	{
		CVAR_SV_FORCE_TRANSMIT_PLAYERS.SetString("1", true, false);
		CreateGlow(client);
	}
	else
	{
		CVAR_SV_FORCE_TRANSMIT_PLAYERS.SetString("0", true, false);
		RemoveSkin(client);
	}
}

public void CreateGlow(int client)
{
	char model[512];
	int skin = -1;
	GetClientModel(client, model, sizeof(model));
	skin = CreatePlayerModelProp(client, model);
	if(skin > MaxClients)
	{
		if(SDKHookEx(skin, SDKHook_SetTransmit, OnSetTransmit_All))
		{
			SetupGlow(skin);
		}
	}
}

public Action OnSetTransmit_All(int entity, int client)
{
	if(g_iPlayerModelsIndex[client] != entity)
	{
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

public void SetupGlow(int entity)
{
	static int offset = -1;
	if ((offset = GetEntSendPropOffs(entity, "m_clrGlow")) == -1)
	{
		LogError("Unable to find property offset: \"m_clrGlow\"!");
		return;
	}

	SetEntProp(entity, Prop_Send, "m_bShouldGlow", true);
	SetEntProp(entity, Prop_Send, "m_nGlowStyle", 0);
	SetEntPropFloat(entity, Prop_Send, "m_flGlowMaxDist", 10000.0);

	//Miku Green
	SetEntData(entity, offset, 57, _, true);
	SetEntData(entity, offset + 1, 197, _, true);
	SetEntData(entity, offset + 2, 187, _, true);
	SetEntData(entity, offset + 3, 155, _, true);

	SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
	SetEntityRenderColor(entity, 255, 255, 255, 0);
}

public int CreatePlayerModelProp(int client, char[] sModel)
{
	RemoveSkin(client);
	int skin = CreateEntityByName("prop_dynamic_glow");
	DispatchKeyValue(skin, "model", sModel);
	DispatchKeyValue(skin, "solid", "0");
	DispatchKeyValue(skin, "fademindist", "1");
	DispatchKeyValue(skin, "fademaxdist", "1");
	DispatchKeyValue(skin, "fadescale", "2.0");
	SetEntProp(skin, Prop_Send, "m_CollisionGroup", 0);
	DispatchSpawn(skin);
	SetEntityRenderMode(skin, RENDER_GLOW);
	SetEntityRenderColor(skin, 0, 0, 0, 0);
	SetEntProp(skin, Prop_Send, "m_fEffects", EF_BONEMERGE);
	SetVariantString("!activator");
	AcceptEntityInput(skin, "SetParent", client, skin);
	SetVariantString("primary");
	AcceptEntityInput(skin, "SetParentAttachment", skin, skin, 0);
	SetVariantString("OnUser1 !self:Kill::0.1:-1");
	AcceptEntityInput(skin, "AddOutput");
	g_iPlayerModels[client] = EntIndexToEntRef(skin);
	g_iPlayerModelsIndex[client] = skin;
	return skin;
}

public void RemoveSkin(int client)
{
	int index = EntRefToEntIndex(g_iPlayerModels[client]);
	if(index > MaxClients && IsValidEntity(index)) {
		SetEntProp(index, Prop_Send, "m_bShouldGlow", false);
		AcceptEntityInput(index, "FireUser1");
	}
	g_iPlayerModels[client] = INVALID_ENT_REFERENCE;
	g_iPlayerModelsIndex[client] = -1;
}

//////////////////////////////
//          Maker           //
//////////////////////////////

public Action PlayerPing(int client, const char[] command, int args)
{
	if(PlayerLeader[client] == true)
	{
		switch(LeaderMakerCount[client])
		{
			case 0:
			{
				if(LeaderMakerEntity[client][0] != -1)
				{
					RemoveMaker(LeaderMakerEntity[client][0]);
				}
				LeaderMakerEntity[client][0] = SpawnMarker(client, LeaderMarkVMT);
				LeaderMakerCount[client] = 1;
			}
			case 1:
			{
				if(LeaderMakerEntity[client][1] != -1)
				{
					RemoveMaker(LeaderMakerEntity[client][1]);
				}
				LeaderMakerEntity[client][1] = SpawnMarker(client, LeaderMarkVMT);
				LeaderMakerCount[client] = 2;
			}
			case 2:
			{
				if(LeaderMakerEntity[client][2] != -1)
				{
					RemoveMaker(LeaderMakerEntity[client][2]);
				}
				LeaderMakerEntity[client][2] = SpawnMarker(client, LeaderMarkVMT);
				LeaderMakerCount[client] = 0;
				Chat(client, "点击鼠标右键清除标记");
			}
		}
	}
	return Plugin_Handled;
}

public int SpawnMarker(int client, char[] sprite)
{
	if(!ClientIsValid(client))
	{
		return -1;
	}

	if(!SetAimEndPoint(client))
	{
		return -1;
	}

	int entity = CreateEntityByName("env_sprite");
	if(!entity) return -1;

	DispatchKeyValue(entity, "model", sprite);
	DispatchKeyValue(entity, "classname", "env_sprite");
	DispatchKeyValue(entity, "spawnflags", "1");
	DispatchKeyValue(entity, "scale", "0.1");
	DispatchKeyValue(entity, "rendermode", "1");
	DispatchKeyValue(entity, "rendercolor", "255 255 255");
	DispatchSpawn(entity);
	TeleportEntity(entity, g_pos[client], NULL_VECTOR, NULL_VECTOR);

	return entity;
}

public bool SetAimEndPoint(int client)
{
	float vAngles[3];
	float vOrigin[3];
	float vBuffer[3];
	float vStart[3];
	float Distance;

	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);

	//get endpoint for spawn marker
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace))
	{
  		TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
		GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		g_pos[client][0] = vStart[0] + (vBuffer[0]*Distance);
		g_pos[client][1] = vStart[1] + (vBuffer[1]*Distance);
		g_pos[client][2] = vStart[2] + (vBuffer[2]*Distance) + 25.0;
	}
	else
	{
		Chat(client, "无法生成标记");
		CloseHandle(trace);
		return false;
	}

	CloseHandle(trace);
	return true;
}

public void RemoveMaker(int Ent)
{
	if(Ent != -1 && IsValidEdict(Ent))
	{
		char m_szClassname[64];
		GetEdictClassname(Ent, m_szClassname, sizeof(m_szClassname));
		if(strcmp("env_sprite", m_szClassname)==0)
		AcceptEntityInput(Ent, "Kill");
	}
}