#pragma semicolon 1
#pragma newdecls required


//////////////////////////////
//    PLUGIN DEFINITION     //
//////////////////////////////
#define PLUGIN_NAME         "Ins.soldier76"
#define PLUGIN_AUTHOR       "Ins"
#define PLUGIN_DESCRIPTION  ""
#define PLUGIN_VERSION      "1.0"
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
#include <sdkhooks>
#include <smutils>

//////////////////////////////
//          DEFINE          //
//////////////////////////////

int g_iFinalTime = 6;
int g_iCurrentTime[MAXPLAYERS + 1] = {0, ...};

float g_fTargetDist = 10000.00;	//锁定目标的距离
float g_Fov = 1000.00;

bool slodier[MAXPLAYERS + 1];
bool slodierGlow[MAXPLAYERS + 1];

ConVar g_cvPredictionConVars[10] = {null, ...};

char g_SoundList[2][128];


//GLOW
#define EF_BONEMERGE                (1 << 0)

int g_iPlayerModelsIndex[MAXPLAYERS + 1] = { -1, ... };
int g_iPlayerModels[MAXPLAYERS + 1] = {INVALID_ENT_REFERENCE, ... };

ConVar CVAR_SV_FORCE_TRANSMIT_PLAYERS = null;

//////////////////////////////
//          Forward         //
//////////////////////////////

public void OnPluginStart()
{

	RegAdminCmd("sm_soldier", autoAim, ADMFLAG_ROOT);

	HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Pre);
	//HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);


	//跑打不扩散
	g_cvPredictionConVars[0] = FindConVar("weapon_accuracy_nospread");
	//为使你的后坐力完全复位,你不能开枪的时间,以秒为单位 默认是0.55
	g_cvPredictionConVars[1] = FindConVar("weapon_recoil_cooldown");
	//此命令设置武器后座力的衰减因子指数 默认是3.5
	g_cvPredictionConVars[2] = FindConVar("weapon_recoil_decay1_exp");
	//此命令设置武器后座力的衰减因子指数 默认是8
	g_cvPredictionConVars[3] = FindConVar("weapon_recoil_decay2_exp");
	//此命令设置武器后座力的衰减因子指数 默认是18
	g_cvPredictionConVars[4] = FindConVar("weapon_recoil_decay2_lin");
	//这个命令设置后坐力的比例系数,即这个数字越高,后坐力越大
	g_cvPredictionConVars[5] = FindConVar("weapon_recoil_scale");
	//可能不起作用
	g_cvPredictionConVars[6] = FindConVar("weapon_recoil_suppression_shots");
	//可能不起作用
	g_cvPredictionConVars[7] = FindConVar("weapon_recoil_variance");
	//这个命令控制当您受到反冲影响时屏幕震动的程度 默认是0.055
	g_cvPredictionConVars[8] = FindConVar("weapon_recoil_view_punch_extra");
	//子弹
	g_cvPredictionConVars[9] = FindConVar("sv_infinite_ammo");

	CVAR_SV_FORCE_TRANSMIT_PLAYERS = FindConVar("sv_force_transmit_players");

	g_SoundList[0] = "sound/airnoins/voice/ow/soldier_1.mp3";
	g_SoundList[1] = "sound/airnoins/voice/ow/soldier_2.mp3";
}

public void OnMapStart()
{
	PrecacheSound(g_SoundList[0], true);
	PrecacheSound(g_SoundList[1], true);
}

public void OnClientPutInServer(int client)
{
	slodier[client] = false;
	slodierGlow[client] = false;
	g_iCurrentTime[client] = 0;
}

//////////////////////////////
//          EVENT           //
//////////////////////////////

public Action Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	if(slodier[iClient])
	{
		int iTarget = GetClosestClient(iClient);
		if(iTarget > 0)
		{
			LookAtClient(iClient, iTarget);
			//ClientCommand(iTarget, "drop");

			//int playerHp = GetEntProp(iClient, Prop_Send, "m_iHealth");
			//SetEntProp(iClient, Prop_Send, "m_iHealth", playerHp - 50);



			/* float angles[3];

			GetClientEyeAngles(iClient, angles);
			Chat(iClient, "%f %f %f", angle[0], angle[1], angle[2]);
			angles[0] = 89.00;

			TeleportEntity(iClient, NULL_VECTOR, angles, NULL_VECTOR); */
		}
		//Chat(iClient, "client: %d %N target: %d %N", iClient, iClient, iTarget, iTarget);
	}
	return Plugin_Continue;
}

/* public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int iTarget = GetClientOfUserId(event.GetInt("userid"));
	int iClient = GetClientOfUserId(event.GetInt("attacker"));
	
	if(slodier[iClient])
	{
		int playerHp = GetEntProp(iTarget, Prop_Send, "m_iHealth");
		SetEntProp(iTarget, Prop_Send, "m_iHealth", playerHp - 50);
	}

	return Plugin_Continue;
} */

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	PerformGlow(iClient);

	return Plugin_Continue;
}

//////////////////////////////
//          COMMAND         //
//////////////////////////////

public Action autoAim(int client, int args)
{
	if(ClientIsValid(client) && ClientIsAlive(client))
	{
		//Chat(client, "%d", GetSteamAccountID(client));
		/* if(GetSteamAccountID(client) == 1276753713)
		{
			startAutoAim(client);
			Hint(client, "战术目镜已焊死");
			return Plugin_Handled;
		} */
		if(slodier[client])
		{
			closeAutoAim(client);
		}
		else
		{
			startAutoAim(client);
			CreateTimer(1.00, autoAim_Timer, client, TIMER_REPEAT);
		}
	}
	return Plugin_Handled;
}

public Action autoAim_Timer(Handle timer, int client)
{
	if(g_iCurrentTime[client] < g_iFinalTime && slodier[client])
	{
		g_iCurrentTime[client] += 1;
		Hint(client, "持续时间: %d/%d", g_iCurrentTime[client], g_iFinalTime);

		return Plugin_Continue;
	}

	g_iCurrentTime[client] = 0;
	closeAutoAim(client);

	return Plugin_Stop;
}

public void closeAutoAim(int client)
{
	if(!ClientIsValid(client)) return;
	Hint(client, "战术目镜关闭...");
	HostileGlow(client, true);
	SendConVarValue(client, g_cvPredictionConVars[0], "0");
	//SendConVarValue(client, g_cvPredictionConVars[8], "0.055");
	SendConVarValue(client, g_cvPredictionConVars[5], "2");
	slodier[client] = false;
}

public void startAutoAim(int client)
{
	Hint(client, "战术目镜启动...");
	HostileGlow(client, false);
	SendConVarValue(client, g_cvPredictionConVars[0], "1");
	//SendConVarValue(client, g_cvPredictionConVars[8], "0");
	SendConVarValue(client, g_cvPredictionConVars[5], "0");
	playSound(client);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(!ClientIsValid(i)) continue;
		if(GetClientTeam(i) != GetClientTeam(client))
		{
			EasyMissionHint(i, 4.00, Icon_alert_red, 255, 40, 40, "我看到你们了");
		}
		else
		{
			EasyMissionHint(i, 4.00, Icon_tip, 0, 225, 65, "战术目镜启动");
		}
	}

	slodier[client] = true;
}

stock void LookAtClient(int iClient, int iTarget)
{
	float fTargetPos[3], fTargetAngles[3], fClientPos[3], fFinalPos[3];
	GetClientEyePosition(iClient, fClientPos);
	GetClientEyePosition(iTarget, fTargetPos);
	GetClientEyeAngles(iTarget, fTargetAngles);
	
	float fVecFinal[3];
	AddInFrontOf(fTargetPos, fTargetAngles, 7.0, fVecFinal);
	MakeVectorFromPoints(fClientPos, fVecFinal, fFinalPos);
	
	GetVectorAngles(fFinalPos, fFinalPos);
	
	//Recoil Control System
	float vecPunchAngle[3];
	
	if (GetEngineVersion() == Engine_CSGO || GetEngineVersion() == Engine_CSS)
	{
		GetEntPropVector(iClient, Prop_Send, "m_aimPunchAngle", vecPunchAngle);
	}
	else
	{
		GetEntPropVector(iClient, Prop_Send, "m_vecPunchAngle", vecPunchAngle);
	}
	
	if(g_cvPredictionConVars[5] != null)
	{
		fFinalPos[0] -= vecPunchAngle[0] * GetConVarFloat(g_cvPredictionConVars[5]);
		fFinalPos[1] -= vecPunchAngle[1] * GetConVarFloat(g_cvPredictionConVars[5]);
	}

	/* int iRandom = RandomInt(0, 100);

	if(iRandom > 90)
	{
		fFinalPos[0] += 0.50;
	}
	else if(iRandom >= 50 && iRandom <=90)
	{
		fFinalPos[0] += 1.00;
	}
	else if(iRandom == 10)
	{
		fFinalPos[0] == 89.00;
	} */

	TeleportEntity(iClient, NULL_VECTOR, fFinalPos, NULL_VECTOR);
	//Chat(iClient, "%f %f %f", fFinalPos[0], fFinalPos[1], fFinalPos[2]);
}

stock void AddInFrontOf(float fVecOrigin[3], float fVecAngle[3], float fUnits, float fOutPut[3])
{
	float fVecView[3]; GetViewVector(fVecAngle, fVecView);
	
	fOutPut[0] = fVecView[0] * fUnits + fVecOrigin[0];
	fOutPut[1] = fVecView[1] * fUnits + fVecOrigin[1];
	fOutPut[2] = fVecView[2] * fUnits + fVecOrigin[2];
}

stock void GetViewVector(float fVecAngle[3], float fOutPut[3])
{
	fOutPut[0] = Cosine(fVecAngle[1] / (180 / FLOAT_PI));
	fOutPut[1] = Sine(fVecAngle[1] / (180 / FLOAT_PI));
	fOutPut[2] = -Sine(fVecAngle[0] / (180 / FLOAT_PI));
}

stock int GetClosestClient(int iClient)
{
	float fClientOrigin[3], fTargetOrigin[3];
	
	GetClientAbsOrigin(iClient, fClientOrigin);
	
	int iClientTeam = GetClientTeam(iClient);
	int iClosestTarget = -1;
	
	float fClosestDistance = -1.0;
	float fTargetDistance;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (ClientIsValid(i, true))
		{
			if (iClient == i || GetClientTeam(i) == iClientTeam || !IsPlayerAlive(i))
			{
				continue;
			}
			
			GetClientAbsOrigin(i, fTargetOrigin);
			fTargetDistance = GetVectorDistance(fClientOrigin, fTargetOrigin);

			if (fTargetDistance > fClosestDistance && fClosestDistance > -1.0)
			{
				continue;
			}

			if (!ClientCanSeeTarget(iClient, i))
			{
				continue;
			}

			if (GetEngineVersion() == Engine_CSGO)
			{
				if (GetEntPropFloat(i, Prop_Send, "m_fImmuneToGunGameDamageTime") > 0.0)
				{
					continue;
				}
			}

			if (g_fTargetDist != 0.0 && fTargetDistance > g_fTargetDist)
			{
				continue;
			}
			
			if (g_Fov != 0.0 && !IsTargetInSightRange(iClient, i, g_Fov, g_fTargetDist))
			{
				continue;
			}
			
			fClosestDistance = fTargetDistance;
			iClosestTarget = i;
		}
	}
	
	return iClosestTarget;
}

stock bool ClientCanSeeTarget(int iClient, int iTarget, float fDistance = 0.0, float fHeight = 50.0)
{
	float fClientPosition[3]; float fTargetPosition[3];
	
	GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", fClientPosition);
	fClientPosition[2] += fHeight;
	
	GetClientEyePosition(iTarget, fTargetPosition);
	
	if (fDistance == 0.0 || GetVectorDistance(fClientPosition, fTargetPosition, false) < fDistance)
	{
		Handle hTrace = TR_TraceRayFilterEx(fClientPosition, fTargetPosition, MASK_SOLID_BRUSHONLY, RayType_EndPoint, Base_TraceFilter);
		
		if (TR_DidHit(hTrace))
		{
			delete hTrace;
			return false;
		}
		
		delete hTrace;
		return true;
	}
	
	return false;
}

public bool Base_TraceFilter(int iEntity, int iContentsMask, int iData)
{
	return iEntity == iData;
}

stock bool IsTargetInSightRange(int client, int target, float angle = 90.0, float distance = 0.0, bool heightcheck = true, bool negativeangle = false)
{
	if (angle > 360.0)
		angle = 360.0;
	
	if (angle < 0.0)
		return false;
	
	float clientpos[3];
	float targetpos[3];
	float anglevector[3];
	float targetvector[3];
	float resultangle;
	float resultdistance;
	
	GetClientEyeAngles(client, anglevector);
	anglevector[0] = anglevector[2] = 0.0;
	GetAngleVectors(anglevector, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector);
	if (negativeangle)
		NegateVector(anglevector);
	
	GetClientAbsOrigin(client, clientpos);
	GetClientAbsOrigin(target, targetpos);
	
	if (heightcheck && distance > 0)
		resultdistance = GetVectorDistance(clientpos, targetpos);
	
	clientpos[2] = targetpos[2] = 0.0;
	MakeVectorFromPoints(clientpos, targetpos, targetvector);
	NormalizeVector(targetvector, targetvector);
	
	resultangle = RadToDeg(ArcCosine(GetVectorDotProduct(targetvector, anglevector)));
	
	if (resultangle <= angle / 2)
	{
		if (distance > 0)
		{
			if (!heightcheck)
				resultdistance = GetVectorDistance(clientpos, targetpos);
			
			if (distance >= resultdistance)
				return true;
			else return false;
		}
		else return true;
	}
	
	return false;
}

public void playSound(int client)
{
	int team = GetClientTeam(client);
	
	//EmitSoundToClient(client, "sound/airnoins/voice/ow/soldier_1.mp3", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.6);
	EmitSoundOne(client, g_SoundList[0]);
	for(int i = 1; i <= MaxClients; i++)
	{
		if(ClientIsValid(i) && client != i)
		{
			if(GetClientTeam(i) == team)
			{
				//EmitSoundToClient(i, g_SoundList[1], client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.6);
				EmitSoundOne(client, g_SoundList[1]);
			}
			else
			{
				//EmitSoundToClient(i, g_SoundList[0], client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.6);
				EmitSoundOne(client, g_SoundList[0]);
			}
		}
	}
}

public void HostileGlow(int client, bool clear)
{
	int team = GetClientTeam(client);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(ClientIsValid(i, true) && GetClientTeam(i) != team)
		{
			if(clear)
			{
				slodierGlow[i] = false;
				PerformGlow(i);
				continue;
			}
			slodierGlow[i] = true;
			PerformGlow(i);
		}
	}
}

//////////////////////////////
//          Glow            //
//////////////////////////////

public void PerformGlow(int client)
{
	if(g_iPlayerModelsIndex[client] == -1 && slodierGlow[client])
	{
		CVAR_SV_FORCE_TRANSMIT_PLAYERS.SetString("1", true, false);
		CreateGlow(client);
	}
	else if(g_iPlayerModelsIndex[client] != -1 && slodierGlow[client])
	{
		CVAR_SV_FORCE_TRANSMIT_PLAYERS.SetString("1", true, false);
		RemoveSkin(client);
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
	for(int i = 1; i <= MaxClients; i++)
	{
		if(g_iPlayerModelsIndex[client] != entity && client == i)
		{
			return Plugin_Continue;
		}
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
	/* SetEntData(entity, offset, 57, _, true);
	SetEntData(entity, offset + 1, 197, _, true);
	SetEntData(entity, offset + 2, 187, _, true);
	SetEntData(entity, offset + 3, 155, _, true); */

	//Red
	SetEntData(entity, offset, 210, _, true);
	SetEntData(entity, offset + 1, 0, _, true);
	SetEntData(entity, offset + 2, 25, _, true);
	SetEntData(entity, offset + 3, 70, _, true);

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