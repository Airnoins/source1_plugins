#pragma semicolon 1
#pragma newdecls required


//未完成

//////////////////////////////
//    PLUGIN DEFINITION     //
//////////////////////////////
#define PLUGIN_NAME         "Ins.Bosshp"
#define PLUGIN_AUTHOR       "Ins"
#define PLUGIN_DESCRIPTION  "Plugin that displays boss and breakable health"
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
#include <sdktools>
#include <smutils>
#include <outputinfo>

//////////////////////////////
//          DEFINE          //
//////////////////////////////

#define BOSS_NAME_LEN 256
#define MAX_BOSSES 16
#define MAX_BREAKABLE_HP 900000

enum HPType 
{
	decreasing,
	increasing,
	none
};


// breakable or math_counter
enum struct Boss
{
	char szDisplayName[BOSS_NAME_LEN];
	char szTargetName[BOSS_NAME_LEN];
	char szHPBarName[BOSS_NAME_LEN];
	char szHPInitName[BOSS_NAME_LEN];

	int type;// 0 = breakable | 1 = math_counter | 2 = monster

	int iBossEnt;
	int iHammerId;
	int iHPCounterEnt;
	int iInitEnt;

	int iMaxBars;
	int iCurrentBars;

	int iHP;
	int iInitHP;
	int iHighestHP;
	int iHighestTotalHP;

	HPType hpBarMode;
	HPType hpMode;

	int iDamage[MAXPLAYERS+1];
	int iLastDamage[MAXPLAYERS+1];
	int iTotalHits;

	bool bDead;
	bool bDeadInit;
	bool bActive;
	bool bHinted;

	int iLastHit;
	int iFirstActive;
}

char sPath[256];

int g_iBosses,
	g_iOutValueOffset;

bool g_bOutputInfo;

float x, y;

Boss bosses[MAX_BOSSES];
//////////////////////////////
//          Forward         //
//////////////////////////////

public void OnPluginStart()
{

	HookEntityOutput("func_physbox", 				"OnHealthChanged", Output_OnHealthChanged);
	HookEntityOutput("func_physbox_multiplayer", 	"OnHealthChanged", Output_OnHealthChanged);
	HookEntityOutput("func_breakable", 				"OnHealthChanged", Output_OnHealthChanged);
	HookEntityOutput("func_physbox", 				"OnBreak", Output_OnBreak);
	HookEntityOutput("func_physbox_multiplayer", 	"OnBreak", Output_OnBreak);
	HookEntityOutput("func_breakable", 				"OnBreak", Output_OnBreak);

	RegConsoleCmd("sm_setd", ddd);

	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);

	LoadConfig();

	g_bOutputInfo = LibraryExists("OutputInfo");
}


//////////////////////////////
//          CMD             //
//////////////////////////////

public void LoadConfig()
{
	char CurrentMap[64];
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/bosshp/%s.cfg", CurrentMap);
	PrintToServer("[LoadConfig] -> Path: %s", sPath);

	if (!FileExists(sPath))
	{
		PrintToServer("[LoadConfig] -> The file does not exist");
		return;
	}

	KeyValues kv = new KeyValues("BossHP");
	if (!kv.ImportFromFile(sPath))
	{
		delete kv;
		return;
	}

	kv.Rewind();

	g_iBosses = 0;
	
	LoadBossConfig_Breakable(kv);
	LoadBossConfig_Math_Counter(kv);
	LoadBossConfig_Monster(kv);
}

public void LoadBossConfig_Breakable(KeyValues kv)
{
	if (!kv.JumpToKey("breakable", false) || !kv.GotoFirstSubKey(false))
		return;
	
	do {

		kv.GetString("targetname", bosses[g_iBosses].szTargetName, BOSS_NAME_LEN, bosses[g_iBosses].szTargetName);
		PrintToServer("[LoadConfig] Index %d -> targetname: %s", g_iBosses, bosses[g_iBosses].szTargetName);
		kv.GetString("displayname", bosses[g_iBosses].szDisplayName, BOSS_NAME_LEN, bosses[g_iBosses].szTargetName);
		PrintToServer("[LoadConfig] Index %d -> displayname: %s", g_iBosses, bosses[g_iBosses].szDisplayName);

		bosses[g_iBosses].type = 0;
		bosses[g_iBosses].bHinted = false;

		g_iBosses++;
	} while(kv.GotoNextKey(false));

	kv.Rewind();
}

public void LoadBossConfig_Math_Counter(KeyValues kv)
{
	if (!kv.JumpToKey("counter", false) || !kv.GotoFirstSubKey(false))
		return;
	
	do {

		kv.GetString("iterator", bosses[g_iBosses].szTargetName, BOSS_NAME_LEN, bosses[g_iBosses].szTargetName);
		kv.GetString("counter", bosses[g_iBosses].szHPBarName, BOSS_NAME_LEN, bosses[g_iBosses].szHPBarName);
		kv.GetString("backup", bosses[g_iBosses].szHPInitName, BOSS_NAME_LEN, bosses[g_iBosses].szHPInitName);
		kv.GetString("displayname", bosses[g_iBosses].szDisplayName, BOSS_NAME_LEN, bosses[g_iBosses].szTargetName);
		int iBarMode = kv.GetNum("countermode", 0);
		if(iBarMode == 1)
		{
			bosses[g_iBosses].hpBarMode = increasing;
			bosses[g_iBosses].iCurrentBars = bosses[g_iBosses].iMaxBars - bosses[g_iBosses].iCurrentBars;
		}
		else if(iBarMode == 2)
		{
			bosses[g_iBosses].hpBarMode = decreasing;
		}
		else
			bosses[g_iBosses].hpBarMode = none;

		bosses[g_iBosses].iMaxBars	  = kv.GetNum("HPbar_max",		10); //now basing it off of current bars on first activation (IF BAR TYPE == DECREASING)
		// PrintToServer("[LoadConfig] Index %d -> HPbar_max: %d", g_iBosses, bosses[g_iBosses].iMaxBars);
		bosses[g_iBosses].iCurrentBars  = kv.GetNum("HPbar_default",	0);
		// PrintToServer("[LoadConfig] Index %d -> HPbar_default: %d", g_iBosses, bosses[g_iBosses].iCurrentBars);

		bosses[g_iBosses].type = 1;
		bosses[g_iBosses].bHinted = false;

		g_iBosses++;
	} while(kv.GotoNextKey(false));

	kv.Rewind();
}

public void LoadBossConfig_Monster(KeyValues kv)
{
	if (!kv.JumpToKey("monster", false) || !kv.GotoFirstSubKey(false))
		return;
	
	do {

		bosses[g_iBosses].iHammerId = kv.GetNum("hammerid", 0);
		PrintToServer("[LoadConfig] Index %d -> hammerid: %d", g_iBosses, bosses[g_iBosses].iHammerId);
		kv.GetString("displayname", bosses[g_iBosses].szDisplayName, BOSS_NAME_LEN, bosses[g_iBosses].szTargetName);
		PrintToServer("[LoadConfig] Index %d -> displayname: %s", g_iBosses, bosses[g_iBosses].szDisplayName);

		bosses[g_iBosses].type = 2;

		g_iBosses++;
	} while(kv.GotoNextKey(false));

	kv.Rewind();
}

stock void AddClientMoney(int client, int money)
{
	SetClientMoney(client, GetClientMoney(client) + money);
}

public void Boss_Hud(int client, int bossIndex)
{
	if(ClientIsValid(client) && ClientIsAlive(client))
	{
		if(bosses[bossIndex].type == 0)
		{
			HitMaker(bosses[bossIndex].iBossEnt, client, 0.5, 24, 197, 255, 1);
		}
		else if(bosses[bossIndex].type == 1)
		{
			
		}
		else if(bosses[bossIndex].type == 2)
		{
			//HitMaker(bosses[bossIndex].iBossEnt, client, 0.5, 24, 197, 255, 3);
			Hint(client, "<span class='fontSize-medium'><font color='#00bfff'>%s</font><font color='#708090'>@%d</font> : <font color='#ff0000'>%d</font></span>", bosses[bossIndex].szDisplayName, bosses[bossIndex].iBossEnt, bosses[bossIndex].iHP);
		}
	}
}

stock int GetCounterValue(int counter)
{
	char szType[64];
	GetEntityClassname(counter, szType, sizeof(szType));

	if(!StrEqual(szType, "math_counter", false)) {
		return -1;
	}

	if(g_iOutValueOffset == -1)
		g_iOutValueOffset = FindDataMapInfo(counter, "m_OutValue");

	if(g_bOutputInfo)
		return RoundFloat(GetOutputActionValueFloat(counter, "m_OutValue"));

	return RoundFloat(GetEntDataFloat(counter, g_iOutValueOffset));
}

stock void BossEasyMissionHintAll(float holdtime, InstructorHud_Icon icon, int r, int g, int b, int entity, const char[] caption, any ...)
{
	InstructorHud hint = new InstructorHud("", entity);
	hint.EasyInit();
	hint.positioning = true;
	hint.color(r, g, b);
	hint.timeout = holdtime;
	hint.icon_onscreen = icon;
	char msg[256];
	VFormat(msg, 256, caption, 8);
	for(int client = 1; client < MaxClients; client++)
	{
		if(ClientIsValid(client))
		{
			SetGlobalTransTarget(client);
			hint.activator_userid = GetClientUserId(client);
			hint.SetString("hint_caption", msg);
			hint.SetString("hint_activator_caption", msg);
			hint.FireToClient(client);
		}
	}
	hint.activator_userid = 0;
	SetGlobalTransTarget(LANG_SERVER);
	hint.Destroy();
}

public void HitMaker(int entity, int attacker, float holdtime, int r, int g, int b, int HealthType)
{	
	if (IsValidEntity(entity) && ClientIsValid(attacker))
	{
		//breakable
		if(HealthType == 1)
		{
			int percentLeft = RoundFloat((bosses[entity].iHP * 1.0 / bosses[entity].iHighestHP) * 100);
			SetHudTextParams(-0.403, -0.32, holdtime, r, g, b, 0, 0, 6.0, 0.0, 0.0);
			ShowHudText(attacker, -1, "\t\t\t╳\n%s[%d%%] : %d\nHit %d | ETA: ", bosses[entity].szDisplayName, percentLeft, bosses[entity].iHP, bosses[entity].iDamage[attacker]);
			return;
		}
		//math_counter
		else if(HealthType == 2)
		{
			
		}
		else
		{
			SetHudTextParams(x, y, holdtime, r, g, b, 0, 0, 6.0, 0.0, 0.0);
			ShowHudText(attacker, -1, "\t\t\t╳");
		}
	}
}

//////////////////////////////
//          EVENT           //
//////////////////////////////

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	LoadConfig();
}

//////////////////////////////
//          HOOK            //
//////////////////////////////

public void Output_OnHealthChanged(const char[] output, int caller, int activator, float delay)
{
	char szName[64], szType[64];
	GetEntityClassname(caller, szType, sizeof(szType));
	GetEntPropString(caller, Prop_Data, "m_iName", szName, sizeof(szName));
	int hammerid = GetEntityHammerID(caller);
	HitMaker(caller, activator, 0.5, 24, 197, 255, false);

	for(int i = 0; i < g_iBosses; i++)
	{
		if(StrEqual(bosses[i].szTargetName, szName, false))
		{
			int hp = GetEntProp(caller, Prop_Data, "m_iHealth");

			if(hp > MAX_BREAKABLE_HP)
				return;

			if(!bosses[i].bHinted)
			{
				bosses[i].bHinted = true;
				BossEasyMissionHintAll(10.00, Icon_tip, 255, 255, 255, caller, "%s", bosses[i].szDisplayName);
			}

			if(hp > bosses[i].iHighestHP)
				bosses[i].iHighestHP = hp;

			//HP和百分比重新校准
			int percentLeft = RoundFloat((hp * 1.0 / bosses[i].iHighestHP) * 100); // if percentLeft <= 75 within the first 3 seconds, reset it
			if(GetTime() - bosses[i].iFirstActive <= 3 && percentLeft <= 75)
			{
				bosses[i].iHighestHP = hp;
			}
			// if 0 percent left and hp >= 1000, reset it
			if(percentLeft == 0 && hp >= 1000)
			{
				bosses[i].iHighestHP = hp;
			}

			bosses[i].iHP = hp;
			bosses[i].iBossEnt = caller;

			if (ClientIsValid(activator))
			{
				if(bosses[i].iTotalHits > 5)
				{
					if(bosses[i].iFirstActive == -1)
						bosses[i].iFirstActive = GetTime();

					bosses[i].bActive = true;
				}

				bosses[i].iLastHit = GetTime();
				bosses[i].iDamage[activator] += 1;
				bosses[i].iTotalHits += 1;

				AddClientMoney(activator, RandomInt(1, 15));

				if(hp <= 0 && bosses[i].hpBarMode == none) 
				{
					bosses[i].bDead = true;
					bosses[i].bDeadInit = true; 
				}
			}

			return;
		}
		else if(bosses[i].iHammerId == hammerid)
		{
			int health = GetEntProp(caller, Prop_Data, "m_iHealth");

			if(health < 0 || health > MAX_BREAKABLE_HP)
				return;

			bosses[i].iHP = health;
			bosses[i].iBossEnt = caller;

			if(ClientIsValid(activator))
			{
				AddClientMoney(activator, RandomInt(1, 15));

				Boss_Hud(activator, i);
			}
		}
	}
}

public void Output_OnBreak(const char[] output, int caller, int activator, float delay)
{
	for (int i = 0; i < g_iBosses; i++)
	{
		if(bosses[i].iBossEnt == caller)
		{
			bosses[i].iHP = 0;
			bosses[i].bDead	 = true;
			bosses[i].bDeadInit  = true;
			bosses[i].bHinted = false;
		}
	}
}

public Action ddd(int client, int args)
{
	//-0.403, -0.32
	x = GetCmdArgFloat(1);
	y = GetCmdArgFloat(2);
	return Plugin_Handled;
}