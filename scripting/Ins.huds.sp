#pragma semicolon 1
#pragma newdecls required


//////////////////////////////
//    PLUGIN DEFINITION     //
//////////////////////////////
#define PLUGIN_NAME         "Ins.huds"
#define PLUGIN_AUTHOR       "Ins"
#define PLUGIN_DESCRIPTION  "Client Hud Manager"
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
#include <sdkhooks>
#include <clientprefs>
#include <smutils>


//////////////////////////////
//          DEFINE          //
//////////////////////////////

#define client_DB "Ins_client"
Database Ins_clientDB;

int g_iDBStatus = 0; // 0 - Def., 1 - Reconnect, 2 - Unknown Driver, 3 - Create Table, 4 - Ready to Query

Handle SyncHUD;
Handle h_InfoHud = null;
Handle h_AimHint = null;
Handle h_HudPosX = null;
Handle h_HudPosY = null;

Handle g_InfoHudTimer = null;
Handle g_AimHintTimer = null;

enum struct Player
{
	bool 		InfoHud;
	bool		AimHint;
	float		HudPosX;
	float		HudPosY;
}

enum struct Hud_Config
{
	char 		Title[32];
	int 		CurrentPlayers;
	int 		MaxCurrentPlayers;
	int			Color[4];
	float		Holdtime;
}

Player PlayerInfo[MAXPLAYERS+1];
Hud_Config InfoHud;

//头像框左侧图片 80x80
int m_nPersonaDataPublicLevel;
//头像框右侧横幅? svg文件
int m_iCompetitiveRanking;

//////////////////////////////
//          Forward         //
//////////////////////////////

public void OnPluginStart()
{
	RegConsoleCmd("sm_infohud", InfoHud_Cookie, "InfoHud enable/disable");
	RegConsoleCmd("sm_infohudpos", Command_Hudpos, "infohud pos");
	RegConsoleCmd("sm_aimhint", AimHint_Cookie, "AimHint enable/disable");

	h_InfoHud = RegClientCookie("InfoHud_cookies", "hud enable/disable", CookieAccess_Protected);
	h_AimHint = RegClientCookie("aimhint_cookies", "aimhint enable/disable", CookieAccess_Protected);
	h_HudPosX  = RegClientCookie("hudposX_cookies", "client infohud posX", CookieAccess_Protected);
	h_HudPosY  = RegClientCookie("hudposY_cookies", "client infohud posY", CookieAccess_Protected);

	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	
	SMUtils_SetChatPrefix("[\x0DIns.huds\x01]");
	SMUtils_SetChatSpaces("   ");
	SMUtils_SetChatConSnd(false);
	SMUtils_SetTextDest(HUD_PRINTCENTER);

	m_nPersonaDataPublicLevel = FindSendPropInfo("CCSPlayerResource", "m_nPersonaDataPublicLevel");
	m_iCompetitiveRanking = FindSendPropInfo("CCSPlayerResource", "m_iCompetitiveRanking");

	SyncHUD = CreateHudSynchronizer();
	Database.Connect(Client_ConnectCallBack, client_DB);
}

public void OnMapStart()
{
	UpdateInfoHudParameter();
	//g_InfoHudTimer = CreateTimer(3.0, Hud_Timer,  _, TIMER_REPEAT);
	g_AimHintTimer = CreateTimer(1.0, AimHint_Timer,  _, TIMER_REPEAT);

	SDKHook(GetPlayerResourceEntity(), SDKHook_ThinkPost, Hook_OnThinkPost);
}

public void OnMapEnd()
{
	delete g_InfoHudTimer;
	delete g_AimHintTimer;
}

public void OnClientPutInServer(int client)
{
	if(!ClientIsValid(client)) return;
	ClientCookiesCheck(client);
}

//////////////////////////////
//          EVENT           //
//////////////////////////////

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{

}

public void Hook_OnThinkPost(int iEnt)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(ClientIsValid(i) && GetSteamAccountID(i) == 895846778)
		{
			SetEntData(iEnt, m_nPersonaDataPublicLevel + i * 4, 4483);
			SetEntData(iEnt, m_iCompetitiveRanking + i * 4, 19002);
		}
	}
}

public void OnPlayerRunCmdPost(int iClient, int iButtons)
{
	static int iOldButtons[MAXPLAYERS+1];

	if(iButtons & IN_SCORE && !(iOldButtons[iClient] & IN_SCORE))
	{
		StartMessageOne("ServerRankRevealAll", iClient, USERMSG_BLOCKHOOKS);
		EndMessage();
	}

	iOldButtons[iClient] = iButtons;
}

//////////////////////////////
//          Timer           //
//////////////////////////////

public void StartTimer()
{
	if(InfoHud.CurrentPlayers > 0)
	{
		if(g_InfoHudTimer != null)
		{
			KillTimer(g_InfoHudTimer);
			g_InfoHudTimer = CreateTimer(60.0, Hud_Timer, _, TIMER_REPEAT);
		}
	}
}

//////////////////////////////
//          InfoHUD         //
//////////////////////////////

public void UpdateInfoHudParameter()
{

	int clientCount = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			++clientCount;
	}

	InfoHud.Title = "风の故乡";
	InfoHud.CurrentPlayers = clientCount;
	InfoHud.MaxCurrentPlayers = GetMaxHumanPlayers();
	InfoHud.Color[0] = 0;
	InfoHud.Color[1] = 200;
	InfoHud.Color[2] = 0;
	InfoHud.Color[3] = 255;
	InfoHud.Holdtime = 3.50;
}

public void UpdateInfoHudClientParameter(int client, char message[512])
{
	if(InfoHud.CurrentPlayers == 0)
	{
		delete g_InfoHudTimer;
		delete g_AimHintTimer;
	}
	int playerid, level, point;
	char name[16], permissions[32];

	GetClientName(client, name, sizeof(name));
	if(GetUserAdmin(client) != INVALID_ADMIN_ID)
		FormatEx(permissions,sizeof(permissions),"%s","Admin");
	else
		FormatEx(permissions,sizeof(permissions),"%s","Member");

	playerid = ST_PlayerInfo(client, 1);
	point = ST_PlayerInfo(client, 2);
	level = ST_PlayerInfo(client, 3);

	PlayerInfo[client].HudPosX = CookiesGetFloat(client, h_HudPosX);
	PlayerInfo[client].HudPosY = CookiesGetFloat(client, h_HudPosY);

	char Date[32], map[32];
	GetCurrentMap(map, sizeof(map));
	GetDate(0, "%Y/%m/%d", Date, sizeof(Date));

	Format(message, sizeof(message), "%s\nPlayers: %d/%d\n名称: %s\nPID: %d\n点数: %d(Lv.%d)\n权限: %s\n地图: %s\n时间: %s", InfoHud.Title, InfoHud.CurrentPlayers, InfoHud.MaxCurrentPlayers, name, playerid, point, level, permissions, map, Date);
}

public Action Hud_Timer(Handle Timer)
{
	for(int i = 1; i < MaxClients; i++)
	{
		if(ClientIsValid(i) && ClientIsAlive(i) && PlayerInfo[i].InfoHud == true)
		{
			char message[512];
			UpdateInfoHudParameter();
			UpdateInfoHudClientParameter(i, message);
			SetHudTextParams(PlayerInfo[i].HudPosX, PlayerInfo[i].HudPosY, InfoHud.Holdtime, InfoHud.Color[0], InfoHud.Color[1], InfoHud.Color[2], InfoHud.Color[3], 0, 0.0, 0.0, 0.0);
			ShowSyncHudText(i, SyncHUD, message);
		}
	}
	return Plugin_Handled;
}

public Action InfoHud_Cookie(int client, int args)
{
	switch(CookiesGetInt(client, h_InfoHud))
	{
		case 0:
		{
			CookiesSetInt(client, h_InfoHud, 1);
			PlayerInfo[client].InfoHud = false;
			ShowSyncHudText(client, SyncHUD, "");
			Chat(client, "信息面板已关闭");
		}
		case 1:
		{
			CookiesSetInt(client, h_InfoHud, 0);
			PlayerInfo[client].InfoHud = true;
			Chat(client, "信息面板已开启");
		}
	}
	return Plugin_Handled;
}

public Action Command_Hudpos(int client, int args)
{
	if((IsClientConnected(client) && IsClientInGame(client)))
	{
		if(GetCmdArgs() < 2)
		{
			Chat(client, "用法: sm_infohudpos <x> <y>");
			return Plugin_Handled;
		}
		char sBuffer[128];
		float HudPosX_validate;
		float HudPosY_validate;
		GetCmdArg(1, sBuffer, sizeof(sBuffer));
		HudPosX_validate = StringToFloat(sBuffer);
		
		GetCmdArg(2, sBuffer, sizeof(sBuffer));
		HudPosY_validate = StringToFloat(sBuffer);
		
		if(((HudPosX_validate >= 0.0 && HudPosX_validate <= 1.0) || HudPosX_validate == -1.0) && ((HudPosY_validate >= 0.0 && HudPosY_validate <= 1.0) || HudPosY_validate == -1.0))
		{
			PlayerInfo[client].HudPosX = HudPosX_validate;
			PlayerInfo[client].HudPosY = HudPosY_validate;
			
			CookiesSetFloat(client, h_HudPosX, HudPosX_validate);
			CookiesSetFloat(client, h_HudPosY, HudPosY_validate);
		}
		else 
		{
			Chat(client, "错误的HUD位置,请重新输入");
			return Plugin_Handled;
		}
		Chat(client, "HUD位置已保存");
	}
	return Plugin_Handled;
}

//////////////////////////////
//          AimHint         //
//////////////////////////////

public Action AimHint_Timer(Handle Timer)
{
	for(int i = 1; i < MaxClients; i++)
	{
		if(ClientIsValid(i) && ClientIsAlive(i) && PlayerInfo[i].AimHint == true)
		{
			int target = GetClientAimTarget(i, true);
			if(ClientIsValid(target) && ClientIsAlive(target))
			{
				int playerid, level, point;
				char name[16], permissions[32], message[1024];
				GetClientName(target, name, sizeof(name));

				if(GetUserAdmin(target) != INVALID_ADMIN_ID)
					FormatEx(permissions,sizeof(permissions),"%s","Admin");
				else
					FormatEx(permissions,sizeof(permissions),"%s","Member");

				playerid = ST_PlayerInfo(target, 1);
				point = ST_PlayerInfo(target, 2);
				level = ST_PlayerInfo(target, 3);

				FormatAimHint(playerid, name, level, point, permissions, message);
				Hint(i, message);
			}
		}
	}
	return Plugin_Handled;
}

public void FormatAimHint(int playerid, char name[16], int level, int point, char permissions[32], char message[1024])
{
	Format(message, sizeof(message), "Lv.<font color='#FF6347'>%d</font> <font color='#1E90FF'>%s</font><br>PID: <font color='#00FF00'>%d</font><br>点数: <font color='#00FF00'>%d</font><br>权限: <font color='#2064ff'>%s</font>", level, name, playerid, point, permissions);
}

public Action AimHint_Cookie(int client, int args)
{
	switch(CookiesGetInt(client, h_AimHint))
	{
		case 0:
		{
			CookiesSetInt(client, h_AimHint, 1);
			PlayerInfo[client].AimHint = false;
			Chat(client, "玩家指针信息已关闭");
		}
		case 1:
		{
			CookiesSetInt(client, h_AimHint, 0);
			PlayerInfo[client].AimHint = true;
			Chat(client, "玩家指针信息已开启");
		}
	}
	return Plugin_Handled;
}

//////////////////////////////
//          Cookie          //
//////////////////////////////

/**
 * Sets a integer value on a cookie.
 *
 * @param client    The client index.
 * @param cookie    The handle to the cookie.
 * @param value     The value to set.
 */
public void CookiesSetInt(int client, Handle cookie, int value)
{
    // Convert value to string.
    char strValue[16];
    IntToString(value, strValue, sizeof(strValue));
    
    // Set string value.
    SetClientCookie(client, cookie, strValue);
}

/**
 * Gets a integer value from a cookie.
 *
 * @param client    The client index.
 * @param cookie    The handle to the cookie.
 */
public int CookiesGetInt(int client, Handle cookie)
{
    char strValue[16];
    strValue[0] = 0;
    GetClientCookie(client, cookie, strValue, sizeof(strValue));
    
    return StringToInt(strValue);
}

public void CookiesSetFloat(int client, Handle cookie, float value)
{
    char strValue[16];
    FloatToString(value, strValue, sizeof(strValue));
    
    SetClientCookie(client, cookie, strValue);
}

public float CookiesGetFloat(int client, Handle cookie)
{
    char strValue[16];
    strValue[0] = 0;
    GetClientCookie(client, cookie, strValue, sizeof(strValue));
    
    return StringToFloat(strValue);
}

public void ClientCookiesCheck(int client)
{
	char scookies[16];
	// InfoHud
	if(CookiesGetInt(client, h_InfoHud) == 0)
	{
		PlayerInfo[client].InfoHud = true;
	}
	else if(CookiesGetInt(client, h_InfoHud) == 1)
	{
		PlayerInfo[client].InfoHud = false;
	}
	else
	{
		CookiesSetInt(client, h_InfoHud, 0);
		PlayerInfo[client].InfoHud = true;
	}

	// AimHint
	if(CookiesGetInt(client, h_AimHint) == 0)
	{
		PlayerInfo[client].AimHint = true;
	}
	else if(CookiesGetInt(client, h_AimHint) == 1)
	{
		PlayerInfo[client].AimHint = false;
	}
	else
	{
		CookiesSetInt(client, h_AimHint, 0);
		PlayerInfo[client].AimHint = true;
	}

	// pos X
	GetClientCookie(client, h_HudPosX, scookies, sizeof(scookies));
	if(StrEqual(scookies, ""))
	{
		CookiesSetFloat(client, h_HudPosX, 0.01);
		PlayerInfo[client].HudPosX = 0.01;
	}

	// pos Y
	GetClientCookie(client, h_HudPosY, scookies, sizeof(scookies));
	if(StrEqual(scookies, ""))
	{
		CookiesSetFloat(client, h_HudPosX, 0.40);
		PlayerInfo[client].HudPosY = 0.40;
	}
}

//////////////////////////////
//          Database        //
//////////////////////////////

public void Client_ConnectCallBack(Database hDatabase, const char[] sError, any data)
{
	if (hDatabase == null)	// Fail Connect
	{
		LogError("[Client DB] Database failure: %s, ReConnect after 60 sec", sError);
		g_iDBStatus = 1; //ReConnect
		CreateTimer(60.00, ReConnectDB);
		return;
	}
	Ins_clientDB = hDatabase;
	g_iDBStatus = 4;
	LogMessage("[Client DB] Successful connection to DB");
}

public Action ReConnectDB(Handle Timer)
{
	if(g_iDBStatus == 1)
	{
		Database.Connect(Client_ConnectCallBack,client_DB);
	}
	return Plugin_Handled;
}

// 1=playerid 2=point 3=level
public int ST_PlayerInfo(int client, int type)
{
	char Query[256], steamid[32];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	FormatEx(Query, sizeof(Query), "SELECT `playerid`, `client_point`, `client_level` FROM `Client_Information` WHERE `client_steamid`='%s'", steamid);
	Handle HQuery = SQL_Query(Ins_clientDB, Query);
	if(HQuery != null)
	{
		if(SQL_FetchRow(HQuery))
		{
			switch(type)
			{
				case 1:
				{
					return SQL_FetchInt(HQuery, 0);
				}
				case 2:
				{
					return SQL_FetchInt(HQuery, 1);
				}
				case 3:
				{
					return SQL_FetchInt(HQuery, 2);
				}
			}
			
		}
	}
	return -1;
}