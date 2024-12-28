#pragma semicolon 1
#pragma newdecls required


//////////////////////////////
//    PLUGIN DEFINITION     //
//////////////////////////////
#define PLUGIN_NAME         "AdminCommand - redux"
#define PLUGIN_AUTHOR       "Ins"
#define PLUGIN_DESCRIPTION  "More administrator commands"
#define PLUGIN_VERSION      "1.0.6"
#define PLUGIN_URL          "https://space.bilibili.com/442385547"

public Plugin myinfo =
{
	name        = PLUGIN_NAME,
	author      = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version     = PLUGIN_VERSION,
	url         = PLUGIN_URL
};


//////////////////////////////
//          INCLUDES        //
//////////////////////////////
#include <sourcemod>
#include <cstrike>
#include <smutils>

//////////////////////////////
//          DEFINE          //
//////////////////////////////

#define MODEL_CHICKEN "models/chicken/chicken.mdl"
#define MODEL_CHICKEN_ZOMBIE "models/chicken/chicken_zombie.mdl"
#define MODEL_BALL "models/props/de_dust/hr_dust/dust_soccerball/dust_soccer_ball001.mdl"

#define SOUND_RESPAWN "player/pl_respawn.wav" //Teleport and respawn sound, leave blank to disable
#define SOUND_CHICKEN "ambient/creatures/chicken_panic_03.wav" //Chicken spawn sound, leave blank to disable
#define SOUND_BURY "physics/concrete/boulder_impact_hard4.wav" //Bury sound, leave blank to disable

Handle SpectatorsMax;

float SaveVec[MAXPLAYERS + 1][2][3];

bool g_toggle[MAXPLAYERS+1];
bool g_allgod = false;

//////////////////////////////
//          Forward         //
//////////////////////////////
public void OnPluginStart()
{
	RegAdminCmd("sm_clearmap", CMD_ClearMap, ADMFLAG_GENERIC, "Deleting dropped weapons");
	RegAdminCmd("sm_rr", CMD_RestartRound, ADMFLAG_GENERIC, "Restarting the game after the specified seconds");
	RegAdminCmd("sm_team", CMD_Team, ADMFLAG_KICK, "Set the targets team");
	RegAdminCmd("sm_spec", CMD_Spec, ADMFLAG_KICK, "Set !activaect team to spectator");
	RegAdminCmd("sm_respawn", CMD_Respawn, ADMFLAG_GENERIC, "Respawn player");
	RegAdminCmd("sm_tele", CMD_Teleport, ADMFLAG_BAN, "Teleporting the target to something");
	RegAdminCmd("sm_speed",	CMD_Speed, ADMFLAG_BAN,	"Set the speed multipiler of the targets");
	RegAdminCmd("sm_god", CMD_God, ADMFLAG_BAN,	"Set godmode for the targets");
	RegAdminCmd("sm_hp", CMD_Health, ADMFLAG_KICK, "Set the health for the targets");
	RegAdminCmd("sm_health", CMD_Health, ADMFLAG_KICK, "Set the health for the targets");
	RegAdminCmd("sm_disarm", CMD_Disarm, ADMFLAG_KICK, "disarm player");
	RegAdminCmd("sm_spawnchicken", CMD_SpawnChicken, ADMFLAG_GENERIC, "Spawn one chicken on your aim position");
	RegAdminCmd("sm_spawnball",	CMD_SpawnBall, ADMFLAG_GENERIC,	"Spawn one ball on your aim position");
	RegAdminCmd("sm_goto", Command_goto, ADMFLAG_BAN, "Teleports an entity");


	RegConsoleCmd("sm_fh", CMD_fh, "Respawn !activaect");

	SMUtils_SetChatPrefix("[\x0DIns.admin\x01]");
	SMUtils_SetChatSpaces("   ");
	SMUtils_SetChatConSnd(true);
	SMUtils_SetTextDest(HUD_PRINTCENTER);

	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);

	SpectatorsMax = FindConVar("mp_spectators_max");

	LoadTranslations("common.phrases");
}

public void OnMapStart()
{
	if(!StrEqual(SOUND_RESPAWN, "", false))
	{
		PrecacheSound(SOUND_RESPAWN, true);
	}
	if(!StrEqual(SOUND_BURY, "", false))
	{
		PrecacheSound(SOUND_BURY, true);
	}
	if(!StrEqual(SOUND_CHICKEN, "", false))
	{
		PrecacheSound(SOUND_CHICKEN, true);
	}

	PrecacheModel(MODEL_CHICKEN, true);
	PrecacheModel(MODEL_CHICKEN_ZOMBIE, true);
	PrecacheModel(MODEL_BALL, true);
}

//////////////////////////////
//          EVENT           //
//////////////////////////////

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(g_toggle[client] == true)
	{
		g_toggle[client] = false;
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_allgod = false;
}

//////////////////////////////
//          COMMAND         //
//////////////////////////////
public Action CMD_ClearMap(int client,int args)
{
	if(!ClientIsValid(client))
	{
		return Plugin_Handled;
	}

	char buffer[64];
	for(char entity = MaxClients; entity < GetMaxEntities(); entity++)
	{
		if(IsValidEntity(entity))
		{
			GetEntityClassname(entity, buffer, sizeof(buffer));
			if(((StrContains(buffer, "weapon_", false) != -1) && (GetEntProp(entity, Prop_Data, "m_iState") == 0) && (GetEntProp(entity, Prop_Data, "m_spawnflags") != 1)) || StrEqual(buffer, "item_defuser", false) || (StrEqual(buffer, "chicken", false) && (GetEntPropEnt(entity, Prop_Send, "m_leader") == -1)))
			{
				AcceptEntityInput(entity, "Kill");
			}
		}
	}

	ChatAll("地图实体已清理");
	LogAction(client, -1, "%L -> clearmap.", client);
	return Plugin_Handled;
}

public Action CMD_RestartRound(int client, int args)
{
	float time;
	if(args)
	{
		char buffer[2];
		GetCmdArg(1, buffer, sizeof(buffer));
		time = StringToFloat(buffer);
	}
	CS_TerminateRound(time, CSRoundEnd_Draw);


	ChatAll("管理员令回合重启");
	LogAction(client, -1, "%L -> Restart round.", client);
	return Plugin_Handled;
}

public Action CMD_Team(int client, int args)
{
	if(!ClientIsValid)
	{
		return Plugin_Handled;
	}

	if((args != 2) && (args != 3))
	{
		return Plugin_Handled;
	}

	char target_name[MAX_TARGET_LENGTH], buffer[512];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	GetCmdArg(1, buffer, sizeof(buffer));
	if((target_count = ProcessTargetString(buffer, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	int team;
	GetCmdArg(2, buffer, sizeof(buffer));
	if(StrEqual(buffer, "spectator", false) || StrEqual(buffer, "spec", false) || StrEqual(buffer, "1", false))
	{
		team = CS_TEAM_SPECTATOR;
		if(tn_is_ml)
		{
			LogAction(client, -1, "%L -> Switch team.", client);
		}
		else
		{
			LogAction(client, -1, "%L -> Switch team.", client);
		}
	}
	else if(StrEqual(buffer, "t", false) || StrEqual(buffer, "2", false))
	{
		team = CS_TEAM_T;
		if(tn_is_ml)
		{
			LogAction(client, -1, "%L -> Switch team.", client);
		}
		else
		{
			LogAction(client, -1, "%L -> Switch team.", client);
		}
	}
	else if(StrEqual(buffer, "ct", false) || StrEqual(buffer, "3", false))
	{
		team = CS_TEAM_CT;
		if(tn_is_ml)
		{
			LogAction(client, -1, "%L -> Switch team.", client);
		}
		else
		{
			LogAction(client, -1, "%L -> Switch team.", client);
		}
	}
	else
	{
		return Plugin_Handled;
	}

	GetCmdArg(3, buffer, sizeof(buffer));
	int value = StringToInt(buffer);

	for(int i = 0; i < target_count; i++)
	{
		if(IsClientInGame(target_list[i]))
		{
			if(value == 1)
			{
				if(team != 1)
				{
					CS_SwitchTeam(target_list[i], team);
					if(IsPlayerAlive(target_list[i]))
					{
						CS_RespawnPlayer(target_list[i]);
					}
				}
				else
				{
					ChangeClientTeam(target_list[i], team);
				}
			}
			else if(args == 2)
			{
				if(team != 1)
				{
					CS_SwitchTeam(target_list[i], team);
					if(IsPlayerAlive(target_list[i]))
					{
						CS_RespawnPlayer(target_list[i]);
					}
				}
				else
				{
					ChangeClientTeam(target_list[i], team);
				}
			}
			else
			{
				if(GetConVarInt(SpectatorsMax) <= 0)
				{
					ChangeClientTeam(target_list[i], team);
				}
				else
				{
					SetEntProp(target_list[i], Prop_Data, "m_iPendingTeamNum", team);
					int frags = GetClientFrags(target_list[i]) +1;
					int deaths = GetClientDeaths(target_list[i])-1;
					int score = CS_GetClientContributionScore(target_list[i])+2;
					SetEntProp(target_list[i], Prop_Data, "m_iFrags", frags);
					SetEntProp(target_list[i], Prop_Data, "m_iDeaths", deaths);
					CS_SetClientContributionScore(target_list[i], score);
				}
			}
		}
	}
	return Plugin_Handled;
}

public Action CMD_Spec(int client,int args)
{
	if(client == 0)
	{
		return Plugin_Handled;
	}

	if(!ClientIsValid(client))
	{
		return Plugin_Handled;
	}
	ChangeClientTeam(client, CS_TEAM_SPECTATOR);
	return Plugin_Handled;
}

public Action CMD_Respawn(int client, int args)
{
	if(!ClientIsValid(client))
	{
		return Plugin_Handled;
	}

	if(args != 1)
	{
		return Plugin_Handled;
	}

	char target_name[MAX_TARGET_LENGTH], buffer[512];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	GetCmdArg(1, buffer, sizeof(buffer));
	if(StrEqual(buffer, "@spec", false) || StrEqual(buffer, "@spectator", false))
	{
		return Plugin_Handled;
	}

	if((target_count = ProcessTargetString(buffer, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(int i = 0; i < target_count; i++)
	{
		if(IsClientInGame(target_list[i]))
		{
			if(GetClientTeam(target_list[i]) >= 2)
			{
				CS_RespawnPlayer(target_list[i]);
				if(!StrEqual(SOUND_RESPAWN, "", false))
				{
					EmitSoundToAll(SOUND_RESPAWN, target_list[i]);
				}
			}
			else if(!tn_is_ml)
			{
				return Plugin_Handled;
			}
		}
	}

	if(tn_is_ml)
	{
		LogAction(client, -1, "%L -> Respawn player.", client);
	}
	else
	{
		LogAction(client, -1, "%L -> Respawn player.", client);
	}
	return Plugin_Handled;
}

public Action CMD_fh(int client, int args)
{
	if(client == 0)
	{
		return Plugin_Handled;
	}

	if(!ClientIsValid(client) && !ClientIsAlive(client))
	{
		return Plugin_Handled;
	}
	if(GetClientTeam(client) <= 1) return Plugin_Handled;

	CS_RespawnPlayer(client);
	return Plugin_Handled;
}

public Action CMD_Disarm(int client, int args)
{
	if(!ClientIsValid)
	{
		return Plugin_Handled;
	}

	if(args != 1)
	{
		return Plugin_Handled;
	}

	char target_name[MAX_TARGET_LENGTH], buffer[512];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	GetCmdArg(1, buffer, sizeof(buffer));
	if((target_count = ProcessTargetString(buffer, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(int i = 0; i < target_count; i++)
	{
		StripWeapon(target_list[i]);
	}

	if(tn_is_ml)
	{
		LogAction(client, -1, "%L -> Disarm player.", client);
	}
	else
	{
		LogAction(client, -1, "%L -> Disarm player.", client);
	}
	return Plugin_Handled;
}

public Action CMD_Teleport(int client, int args)
{
	if(!ClientIsValid(client))
	{
		return Plugin_Handled;
	}

	if((args != 1) && (args != 2))
	{
		return Plugin_Handled;
	}

	char target_name[MAX_TARGET_LENGTH], buffer[512];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	GetCmdArg(1, buffer, sizeof(buffer));

	if((target_count = ProcessTargetString(buffer, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	float vec[2][3];
	GetCmdArg(2, buffer, sizeof(buffer));
	if(!StrEqual(buffer, "", false))
	{
		if(StrEqual(buffer, "@blink", false))
		{
			GetClientEyePosition(client, vec[0]);
			GetClientEyeAngles(client, vec[1]);

			Handle trace = TR_TraceRayFilterEx(vec[0], vec[1], MASK_SOLID, RayType_Infinite, Filter_ExcludePlayers);
			if(!TR_DidHit(trace))
			{
				return Plugin_Handled;
			}
			TR_GetEndPosition(vec[0], trace);
			CloseHandle(trace);

			vec[1][0] = 0.0;

			if(tn_is_ml)
			{
				LogAction(client, -1, "%L -> Teleport player.", client);
			}
			else
			{
				LogAction(client, -1, "%L -> Teleport player.", client);
			}
		}
		else
		{
			char target = FindTarget(client, buffer, false, false);
			if(!ClientIsValid(target))
			{
				return Plugin_Handled;
			}

			GetClientAbsOrigin(target, vec[0]);
			GetClientEyeAngles(target, vec[1]);

			if(tn_is_ml)
			{
				LogAction(client, -1, "%L -> Teleport player.", client);
			}
			else
			{
				LogAction(client, -1, "%L -> Teleport player.", client);
			}
		}
	}
	else
	{
		if((SaveVec[client][0][0] + SaveVec[client][0][1] + SaveVec[client][0][2]) == 0)
		{
			return Plugin_Handled;
		}
		else
		{
			vec[0] = SaveVec[client][0];
			vec[1] = SaveVec[client][1];

			if(tn_is_ml)
			{
				LogAction(client, -1, "%L -> Teleport player.", client);
			}
			else
			{
				LogAction(client, -1, "%L -> Teleport player.", client);
			}
		}
	}

	vec[0][2] = vec[0][2] + 2.0;

	for(int i = 0; i < target_count; i++)
	{
		if(IsClientInGame(target_list[i]))
		{
			TeleportEntity(target_list[i], vec[0], vec[1], view_as<float>({0.0, 0.0, 0.0}));
		}
	}

	if(!StrEqual(SOUND_RESPAWN, "", false))
	{
		EmitSoundToAll(SOUND_RESPAWN, target_list[target_count - 1]);
	}
	return Plugin_Handled;
}

public bool Filter_ExcludePlayers(int entity, int contentsMask, any data)
{
	return !((entity > 0) && (entity <= MaxClients));
}

public Action CMD_Speed(int client, int args)
{
	if(!ClientIsValid(client))
	{
		return Plugin_Handled;
	}

	if(args != 2)
	{
		return Plugin_Handled;
	}

	char target_name[MAX_TARGET_LENGTH], buffer[512];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	GetCmdArg(1, buffer, sizeof(buffer));
	if((target_count = ProcessTargetString(buffer, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	GetCmdArg(2, buffer, sizeof(buffer));
	float value = StringToFloat(buffer);
	if((value < 0.0) || (value > 500.0))
	{
		return Plugin_Handled;
	}

	for(int i = 0; i < target_count; i++)
	{
		SetEntPropFloat(target_list[i], Prop_Data, "m_flLaggedMovementValue", value);
	}

	if(tn_is_ml)
	{
		LogAction(client, -1, "%L -> Set player speed.", client);
	}
	else
	{
		LogAction(client, -1, "%L -> Set player speed.", client);
	}
	return Plugin_Handled;
}

public Action CMD_God(int client, int args)
{
	if(!ClientIsValid(client))
	{
		return Plugin_Handled;
	}
	if(!args)
	{
		if(g_toggle[client] == true)
		{
			g_toggle[client] = false;
			SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
			ChatAll("设置自身的GOD模式 \x07关闭", client);
		}
		else
		{
			g_toggle[client] = true;
			SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
			ChatAll("设置自身的GOD模式 \x04开启", client);
		}
		LogAction(client, -1, "%L -> Set player god.", client);
		return Plugin_Handled;
	}

	char target_name[MAX_TARGET_LENGTH], buffer[512], buffer2[512];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml, isall = false;

	GetCmdArg(1, buffer, sizeof(buffer));
	if(StrEqual(buffer, "@all", false))
	{
		isall = true;
	}
	if((target_count = ProcessTargetString(buffer, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	GetCmdArg(2, buffer2, sizeof(buffer2));
	int mode = StringToInt(buffer2);

	for(int i = 0; i < target_count; i++)
	{
		if(isall)
		{
			if(g_allgod)
			{
				g_allgod = false;
				SetEntProp(target_list[i], Prop_Data, "m_takedamage", 2, 1);
				ChatAll("管理员 \x0D%N \x01设置 \x10全体玩家 \x01的GOD模式 \x07关闭", client);
			}
			else
			{
				g_allgod = true;
				SetEntProp(target_list[i], Prop_Data, "m_takedamage", 0, 1);
				ChatAll("管理员 \x0D%N \x01设置 \x10全体玩家 \x01的GOD模式 \x04开启", client);
			}
			LogAction(client, -1, "%L -> Set player god.", client);
			return Plugin_Handled;
		}
		if(!mode)
		{
			g_toggle[target_list[i]] = false;
			SetEntProp(target_list[i], Prop_Data, "m_takedamage", 2, 1);
			ChatAll("管理员 \x0D%N \x01设置 \x10%N \x01的GOD模式 \x07关闭", client, target_list[i]);
		}
		else
		{
			g_toggle[target_list[i]] = true;
			SetEntProp(target_list[i], Prop_Data, "m_takedamage", 0, 1);
			ChatAll("管理员 \x0D%N \x01设置 \x10%N \x01的GOD模式 \x04开启", client, target_list[i]);
		}
	}

	if(tn_is_ml)
	{
		LogAction(client, -1, "%L -> Set player god.", client);
	}
	else
	{
		LogAction(client, -1, "%L -> Set player god.", client);
	}
	return Plugin_Handled;
}

public Action CMD_Health(int client, int args)
{
	if(!ClientIsValid(client))
	{
		return Plugin_Handled;
	}
	if(args == 1)
	{
		int health = GetCmdArgInt(args);
		if(health <= 0) return Plugin_Handled;
		SetEntProp(client, Prop_Data, "m_iHealth", health);
		ChatAll("设置自身的血量为 \x04%d", health);
		return Plugin_Handled;
	}

	char target_name[MAX_TARGET_LENGTH], buffer[512];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml, isall = false;

	GetCmdArg(1, buffer, sizeof(buffer));
	if(StrEqual(buffer, "@all", false))
	{
		isall = true;
	}
	if((target_count = ProcessTargetString(buffer, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	GetCmdArg(2, buffer, sizeof(buffer));
	int value = StringToInt(buffer);

	if (value <= 0)
	{
		return Plugin_Handled;
	}

	for(int i = 0; i < target_count; i++)
	{
		if((buffer[0] == '+') || (buffer[0] == '-'))
		{
			value = value + GetEntProp(target_list[i], Prop_Data, "m_iHealth");
		}
		if(isall)
		{
			SetEntProp(target_list[i], Prop_Data, "m_iHealth", value);
			ChatAll("管理员 \x0D%N \x01设置 \x10全体玩家 \x01的血量为 \x04%d", client, value);
		}
		else
		{
			SetEntProp(target_list[i], Prop_Data, "m_iHealth", value);
			ChatAll("管理员 \x0D%N \x01设置 \x10%N \x01的血量为 \x04%d", client, target_list[i], value);
		}
	}

	if(tn_is_ml)
	{
		LogAction(client, -1, "%L -> Set player health.", client);
	}
	else
	{
		LogAction(client, -1, "%L -> Set player health.", client);
	}
	return Plugin_Handled;
}

public Action CMD_SpawnChicken(int client, int args)
{
	if(!ClientIsValid(client))
	{
		return Plugin_Handled;
	}

	float vec[2][3];
	GetClientEyePosition(client, vec[0]);
	GetClientEyeAngles(client, vec[1]);

	Handle trace = TR_TraceRayFilterEx(vec[0], vec[1], MASK_SOLID, RayType_Infinite, Filter_ExcludePlayers);
	if(!TR_DidHit(trace))
	{
		return Plugin_Handled;
	}
	TR_GetEndPosition(vec[0], trace);
	CloseHandle(trace);

	char buffer[6][4];
	char values[6];

	for(int i = 0; i <= 5; i++)
	{
		GetCmdArg(i + 1, buffer[i], sizeof(buffer[]));
		values[i] = StringToInt(buffer[i]);
	}

	if(((values[0] < 0) || (values[0] > 6)) || ((values[1] < -1) || (values[1] > 9999)) || ((values[2] < 0) || (values[2] > 255)) || ((values[3] < 0) || (values[3] > 255)) || ((values[4] < 0) || (values[4] > 255)) || ((values[5] < 0) || (values[5] > 3)))
	{
		return Plugin_Handled;
	}

	char chicken = CreateEntityByName("chicken");
	if(!IsValidEntity(chicken))
	{
		return Plugin_Handled;
	}

	char color[16];
	Format(color, sizeof(color), "%s %s %s", buffer[2], buffer[3], buffer[4]);
	DispatchKeyValue(chicken, "glowcolor", color);
	DispatchKeyValue(chicken, "glowdist", "640");
	DispatchKeyValue(chicken, "glowstyle", buffer[5]);
	DispatchKeyValue(chicken, "glowenabled", "1");
	DispatchKeyValue(chicken, "ExplodeDamage", buffer[1]);
	DispatchKeyValue(chicken, "ExplodeRadius", "0");
	DispatchSpawn(chicken);

	if(values[1] < 0)
	{
		SetEntProp(chicken, Prop_Data, "m_takedamage", 0);
	}

	if(values[0] == 6)
	{
		SetEntityModel(chicken, MODEL_CHICKEN_ZOMBIE);
	}
	else
	{
		SetEntProp(chicken, Prop_Data, "m_nSkin", GetRandomInt(0, 1));
		SetEntProp(chicken, Prop_Data, "m_nBody", values[0]);
	}

	vec[0][2] = vec[0][2] + 10.0;
	TeleportEntity(chicken, vec[0], NULL_VECTOR, NULL_VECTOR);

	if(!StrEqual(SOUND_CHICKEN, "", false))
	{
		EmitSoundToAll(SOUND_CHICKEN, chicken);
	}

	LogAction(client, -1, "%L -> Spawn chicken.", client);
	return Plugin_Handled;
}

public Action CMD_SpawnBall(int client, int args)
{
	if(!ClientIsValid(client))
	{
		return Plugin_Handled;
	}

	float vec[2][3];
	GetClientEyePosition(client, vec[0]);
	GetClientEyeAngles(client, vec[1]);

	Handle trace = TR_TraceRayFilterEx(vec[0], vec[1], MASK_SOLID, RayType_Infinite, Filter_ExcludePlayers);
	if(!TR_DidHit(trace))
	{
		return Plugin_Handled;
	}
	TR_GetEndPosition(vec[0], trace);
	CloseHandle(trace);

	char ball = CreateEntityByName("prop_physics_multiplayer");
	if(!IsValidEntity(ball))
	{
		return Plugin_Handled;
	}

	DispatchKeyValue(ball, "model", MODEL_BALL);
	DispatchKeyValue(ball, "physicsmode", "2");
	DispatchSpawn(ball);

	vec[0][2] = vec[0][2] + 16.0;
	TeleportEntity(ball, vec[0], NULL_VECTOR, NULL_VECTOR);

	LogAction(client, -1, "%L -> Spawn ball.", client);
	return Plugin_Handled;
}

public Action Command_goto(int client, int args)
{
	if(ClientIsValid(client) && ClientIsAlive(client))
	{
		sGotoMenu(client);
	}
	return Plugin_Handled;
}

public void sGotoMenu(int client)
{
	if (!ClientIsValid(client)) return;

	Menu sMenu = new Menu(sGotoMenuCallBack);
	sMenu.SetTitle("传送菜单");
	sMenu.AddItem("0", "传送某个玩家到自身位置 \n 1654165465s");
	sMenu.AddItem("1", "传送自己到某个玩家位置");
	sMenu.ExitBackButton = true;
	sMenu.Display(client, 15);
}

public int sGotoMenuCallBack(Menu hMenu, MenuAction hAction, int iClient, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Select:
		{
			char sOption[32];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));
			int sNum = StringToInt(sOption);
			switch(sNum)
			{
				case 0:
				{
					GotoMenu(iClient, 0);
				}
				case 1:
				{
					GotoMenu(iClient, 1);
				}
			}
		}
	}
	return 0;
}

//type 0=传送某个玩家到自身位置 | 1=传送自己到某个玩家位置
public void GotoMenu(int client, int type)
{
	if (!ClientIsValid(client)) return;

	if(type == 0)
	{
		Menu GMenu = new Menu(GotoMenuCallBack1);
		GMenu.SetTitle("Player:");

		bool bNotFound = true;
		char sMenuTemp[64], sIndexTemp[32];
		for (int i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i) || IsFakeClient(i) || (client == i)) continue;

			bNotFound = false;
			FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i", GetClientUserId(i));
			FormatEx(sMenuTemp, sizeof(sMenuTemp), "%N |#%s", i, sIndexTemp);
			GMenu.AddItem(sIndexTemp, sMenuTemp);
		}
		if(bNotFound)
		{
			FormatEx(sMenuTemp, sizeof(sMenuTemp), "%s", "No Players");
			GMenu.AddItem("", sMenuTemp, ITEMDRAW_DISABLED);
		}
		GMenu.ExitBackButton = true;
		GMenu.Display(client, 15);
	}
	else if(type == 1)
	{
		Menu GMenu = new Menu(GotoMenuCallBack2);
		GMenu.SetTitle("Player:");

		bool bNotFound = true;
		char sMenuTemp[64], sIndexTemp[32];
		for (int i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i) || IsFakeClient(i) || (client == i)) continue;

			bNotFound = false;
			FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i", GetClientUserId(i));
			FormatEx(sMenuTemp, sizeof(sMenuTemp), "%N |#%s", i, sIndexTemp);
			GMenu.AddItem(sIndexTemp, sMenuTemp);
		}
		if(bNotFound)
		{
			FormatEx(sMenuTemp, sizeof(sMenuTemp), "%s", "No Players");
			GMenu.AddItem("", sMenuTemp, ITEMDRAW_DISABLED);
		}
		GMenu.ExitBackButton = true;
		GMenu.Display(client, 15);
	}
}

//传送某个玩家到自身位置
public int GotoMenuCallBack1(Menu hMenu, MenuAction hAction, int iClient, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if (iParam2 == MenuCancel_ExitBack) sGotoMenu(iClient);
		case MenuAction_Select:
		{
			char sOption[32];
			float vec[2][3];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));
			int iTarget = GetClientOfUserId(StringToInt(sOption));
			if(ClientIsValid(iTarget) && ClientIsAlive(iTarget))
			{
				GetClientAbsOrigin(iClient, vec[0]);
				GetClientEyeAngles(iClient, vec[1]);
				TeleportEntity(iTarget, vec[0], vec[1], NULL_VECTOR);
				ChatAll("%N 传送至 %N", iTarget, iClient);
			}
			else
			{
				Chat(iClient, "该玩家不是一个有效的实体");
			}
		}
	}
	return 0;
}

//传送自身到某个玩家位置
public int GotoMenuCallBack2(Menu hMenu, MenuAction hAction, int iClient, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if (iParam2 == MenuCancel_ExitBack) sGotoMenu(iClient);
		case MenuAction_Select:
		{
			char sOption[32];
			float vec[2][3];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));
			int iTarget = GetClientOfUserId(StringToInt(sOption));
			if(ClientIsValid(iTarget) && ClientIsAlive(iTarget))
			{
				GetClientAbsOrigin(iTarget, vec[0]);
				GetClientEyeAngles(iTarget, vec[1]);
				TeleportEntity(iClient, vec[0], vec[1], NULL_VECTOR);
				ChatAll("%N 传送至 %N", iClient, iTarget);
			}
			else
			{
				Chat(iClient, "该玩家不是一个有效的实体");
			}
		}
	}
	return 0;
}