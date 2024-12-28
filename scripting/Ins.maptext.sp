#pragma semicolon 1
#pragma newdecls required


//////////////////////////////
//    PLUGIN DEFINITION     //
//////////////////////////////
#define PLUGIN_NAME         "Ins.MapText Manager"
#define PLUGIN_AUTHOR       "Ins"
#define PLUGIN_DESCRIPTION  "Maptext manager"
#define PLUGIN_VERSION      "1.0.8"
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
#include <geoip>
#include <clientprefs>
#include <DynamicChannels>


//////////////////////////////
//          DEFINE          //
//////////////////////////////

#define MAXLENGTH_INPUT 512
#define prefix "[\x0DIns.MapText\x01] "
#define normal_Tag "[\x04地图\x01] \x07>\x04>\x0B> \x06"	//正常输出文本的前缀
#define defect_Tag "[\x04地图\x01] \x07>\x04>\x0B> \x0D"	//地图缺失翻译文本的前缀

char lastMessage[MAXLENGTH_INPUT] = "";
char Path[PLATFORM_MAX_PATH];

char Blacklist[][] = {
	"recharge", "recast", "cooldown", "cool"
};

int lastMessageTime = -1;
int roundStartedTime = -1;
int number;
int HUD_num = 0;
int value0 = 0;
int value1 = 1;

Handle kv;
Handle g_defect_text_display;
//Handle HudSync;

ConVar g_cBlockSpam;
ConVar g_cBlockSpamDelay;

//////////////////////////////
//          Forward         //
//////////////////////////////

public void OnPluginStart()
{
	AddCommandListener(MapText, "say");

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);

//	HudSync = CreateHudSynchronizer();

	g_cBlockSpam = CreateConVar("sm_block_spam", "0", "Blocks console messages that repeat the same message.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cBlockSpamDelay = CreateConVar("sm_block_spam_delay", "1", "Time to wait before printing the same message", FCVAR_NONE, true, 1.0, true, 60.0);

	g_defect_text_display = RegClientCookie("defect_text_display_cookies", "defect_text_display Cookies", CookieAccess_Protected);
	RegConsoleCmd("sm_dtd", defect_text_display_toggle, "defect_text_display_toggle");

	SMUtils_SetChatPrefix("");
	SMUtils_SetChatSpaces("   ");
	SMUtils_SetChatConSnd(false);
	SMUtils_SetTextDest(HUD_PRINTCENTER);

	AutoExecConfig(true, "Ins.maptext");
}

public void OnMapStart()
{
	ReadT();
}

public void OnClientConnected(int client)
{
	if(!ClientIsValid(client)) return;
	if(GetUserAdmin(client) != INVALID_ADMIN_ID)
	{
		char arg[3];
		Format(arg, sizeof(arg), "%i", value0);
		SetClientCookie(client, g_defect_text_display, arg);
	}		
}


//////////////////////////////
//          COMMAND         //
//////////////////////////////

public void ReadT()
{
	delete kv;

	char map[64];
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, Path, sizeof(Path), "configs/consoletext/%s.txt", map);

	kv = CreateKeyValues("Console_T");

	if(!FileExists(Path)) KeyValuesToFile(kv, Path);
	else FileToKeyValues(kv, Path);
}

public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	roundStartedTime = GetTime();
//	DeleteHUD();
//	DeleteTimer();
}

public Action MapText(int client, const char[] command, int args)
{
	if (client)
		return Plugin_Continue;

	char sText[MAXLENGTH_INPUT], dText[MAXLENGTH_INPUT];
	GetCmdArgString(sText, sizeof(sText));
	GetCmdArgString(dText, sizeof(dText));
	StripQuotes(sText);

	if (g_cBlockSpam.BoolValue)
	{
		int currentTime = GetTime();
		if (StrEqual(sText, lastMessage, true))
		{
			if (lastMessageTime != -1 && ((currentTime - lastMessageTime) <= g_cBlockSpamDelay.IntValue))
			{
				lastMessage = sText;
				lastMessageTime = currentTime;
				return Plugin_Handled;
			}
		}
		lastMessage = sText;
		lastMessageTime = currentTime;
	}

	if(kv == null)
	{
		ReadT();
	}
	if(!KvJumpToKey(kv, sText))
	{
		KvJumpToKey(kv, sText, true);
		KvSetString(kv, "chi", " ");
		KvRewind(kv);
		KeyValuesToFile(kv, Path);
		KvJumpToKey(kv, sText);
	}
	bool blocked = (KvGetNum(kv, "blocked", 0)?true:false);
	if(blocked)
	{
		KvRewind(kv);
		return Plugin_Handled;
	}

	char sFinalText[1024];
	char sConsoleTag[255];
	char sCountryTag[4];
	char sIP[26];
	bool isCountable = IsCountable(sText);
	bool NO_Translate = false;

	Format(sConsoleTag, sizeof(sConsoleTag), normal_Tag);

	for(int i = 1 ; i < MaxClients; i++)
	{
		if(IsClientInGame(i))
		{

			GetClientIP(i, sIP, sizeof(sIP));
			GeoipCountryEx(sIP, sCountryTag, sizeof(sCountryTag), i);
			KvGetString(kv, sCountryTag, sText, sizeof(sText), "LANGMISSING");

			if(StrEqual(sText, " ") || StrEqual(sText, "LANGMISSING"))
			{
				Format(sText, sizeof(sText), dText);
				Format(sConsoleTag, sizeof(sConsoleTag), defect_Tag);
				NO_Translate = true;
			}

			Format(sFinalText, sizeof(sFinalText), "%s%s", sConsoleTag, sText);

			if(isCountable && GetRoundTimeAtTimerEnd() > 0)
			{
				float fMinutes = GetRoundTimeAtTimerEnd() / 60.0;
				int minutes = RoundToFloor(fMinutes);
				int seconds = GetRoundTimeAtTimerEnd() - minutes * 60;
				char roundTimeText[32];

				Format(roundTimeText, sizeof(roundTimeText), " \x10@ %i:%s%i", minutes, (seconds < 10 ? "0" : ""), seconds);
				Format(sFinalText, sizeof(sFinalText), "%s%s", sFinalText, roundTimeText);
			}

			Chat(i, sFinalText);

			if (!isCountable)
			{
				SendHudMsg(i, sText);
			}
			else if(isCountable)
			{
				SendNewHudMsg(i, sText, true);
			}
			if(GetUserAdmin(i) != INVALID_ADMIN_ID)
			{
				if(NO_Translate)
				{
					char arg[3];
					GetClientCookie(i, g_defect_text_display, arg, sizeof(arg));
					int value = StringToInt(arg);
					if(value == 0)
					{
						Chat(i, "%s%s", prefix, "\x07该地图有未翻译的文本,详情请打开控制台查看");
						Chat(i, "%s%s", prefix, "\x06该地图有未翻译的文本,详情请打开控制台查看");
						Chat(i, "%s%s", prefix, "\x0C该地图有未翻译的文本,详情请打开控制台查看");
						PrintToConsole(i, "\n[MapText] --> %s\n", dText);
					}
				}
			}
		}
	}
	KvRewind(kv);

	return Plugin_Handled;
}

public Action defect_text_display_toggle(int client, int args)
{
	if(GetUserAdmin(client) == INVALID_ADMIN_ID) return Plugin_Handled;
	if(!ClientIsValid(client)) return Plugin_Handled;
	char arg[3];
	GetClientCookie(client, g_defect_text_display, arg, sizeof(arg));
	int value = StringToInt(arg);
	if(value == 0)
	{
		char arg1[3];
		Format(arg1, sizeof(arg1), "%i", value1);
		SetClientCookie(client, g_defect_text_display, arg1);
		Chat(client, "%s缺失文本提示已\x07关闭", prefix);
	}
	else if(value == 1)
	{
		char arg0[3];
		Format(arg0, sizeof(arg0), "%i", value0);
		SetClientCookie(client, g_defect_text_display, arg0);
		Chat(client, "%s缺失文本提示已\x04开启", prefix);
	}
	return Plugin_Handled;
}

public bool IsCountable(const char sMessage[MAXLENGTH_INPUT])
{
	char FilterText[sizeof(sMessage)+1], ChatArray[32][MAXLENGTH_INPUT];
	int consoleNumber, filterPos;
	bool isCountable = false;

	for (int i = 0; i < sizeof(sMessage); i++)
	{
		if (IsCharAlpha(sMessage[i]) || IsCharNumeric(sMessage[i]) || IsCharSpace(sMessage[i]))
		{
			FilterText[filterPos++] = sMessage[i];
		}
	}
	FilterText[filterPos] = '\0';
	TrimString(FilterText);

	if(CheckString(sMessage))
		return isCountable;

	int words = ExplodeString(FilterText, " ", ChatArray, sizeof(ChatArray), sizeof(ChatArray[]));

	if(words == 1)
	{
		if(StringToInt(ChatArray[0]) != 0)
		{
			isCountable = true;
			consoleNumber = StringToInt(ChatArray[0]);
		}
	}

	for(int i = 0; i <= words; i++)
	{
		if(StringToInt(ChatArray[i]) != 0)
		{
			if(i + 1 <= words && (StrEqual(ChatArray[i + 1], "s", false) || (CharEqual(ChatArray[i + 1][0], 's') && CharEqual(ChatArray[i + 1][1], 'e'))))
			{
				consoleNumber = StringToInt(ChatArray[i]);
				isCountable = true;
			}
			if(!isCountable && i + 2 <= words && (StrEqual(ChatArray[i + 2], "s", false) || (CharEqual(ChatArray[i + 2][0], 's') && CharEqual(ChatArray[i + 2][1], 'e'))))
			{
				consoleNumber = StringToInt(ChatArray[i]);
				isCountable = true;
			}
		}
		if(!isCountable)
		{
			char word[MAXLENGTH_INPUT];
			strcopy(word, sizeof(word), ChatArray[i]);
			int len = strlen(word);

			if(IsCharNumeric(word[0]))
			{
				if(IsCharNumeric(word[1]))
				{
					if(IsCharNumeric(word[2]))
					{
						if(CharEqual(word[3], 's'))
						{
							consoleNumber = StringEnder(word, 5, len);
							isCountable = true;
						}
					}
					else if(CharEqual(word[2], 's'))
					{
						consoleNumber = StringEnder(word, 4, len);
						isCountable = true;
					}
				}
				else if(CharEqual(word[1], 's'))
				{
					consoleNumber = StringEnder(word, 3, len);
					isCountable = true;
				}
			}
		}
		if(isCountable)
		{
			number = consoleNumber;
			break;
		}
	}
	return isCountable;
}

public bool CheckString(const char[] string)
{
	for (int i = 0; i < sizeof(Blacklist); i++)
	{
		if(StrContains(string, Blacklist[i], false) != -1)
		{
			return true;
		}
	}
	return false;
}

public bool CharEqual(int a, int b)
{
	if(a == b || a == CharToLower(b) || a == CharToUpper(b))
	{
		return true;
	}
	return false;
}

public int StringEnder(char[] a, int b, int c)
{
	if(CharEqual(a[b], 'c'))
	{
		a[c - 3] = '\0';
	}
	else
	{
		a[c - 1] = '\0';
	}
	return StringToInt(a);
}

public int GetCurrentRoundTime()
{
	Handle hFreezeTime = FindConVar("mp_freezetime"); // Freezetime Handle
	int freezeTime = GetConVarInt(hFreezeTime); // Freezetime in seconds
	return GameRules_GetProp("m_iRoundTime") - ( (GetTime() - roundStartedTime) - freezeTime );
}

public int GetRoundTimeAtTimerEnd()
{
	return GetCurrentRoundTime() - number;
}

//public void DeleteHUD()
//{
//	HUD_num = 0;
//	for (int i = 1; i <= MAXPLAYERS + 1; i++)
//	{
//		if(ClientIsValid(i))
//		{
//			ClearSyncHud(i, HudSync);
//		}
//	}
//}

public void SendHudMsg(int client, char[] szMessage)
{
	float holdtime = 3.5;
	switch(HUD_num)
	{
		case 0:
		{
			SetHudTextParams(-1.0, 0.10, holdtime, 0, 250, 0, 255, 0, 0.0, 0.0, 0.0);
			ShowHudText(client, GetDynamicChannel(0), szMessage);
		}
		case 1:
		{
			SetHudTextParams(-1.0, 0.125, holdtime, 0, 250, 0, 255, 0, 0.0, 0.0, 0.0);
			ShowHudText(client, GetDynamicChannel(1), szMessage);
		}
		case 2:
		{
			SetHudTextParams(-1.0, 0.15, holdtime, 0, 250, 0, 255, 0, 0.0, 0.0, 0.0);
			ShowHudText(client, GetDynamicChannel(2), szMessage);
		}
		case 3:
		{
			SetHudTextParams(-1.0, 0.10, holdtime, 0, 250, 0, 255, 0, 0.0, 0.0, 0.0);
			ShowHudText(client, GetDynamicChannel(0), szMessage);
			HUD_num = 0;
		}
	}
	HUD_num++;
}

public void SendNewHudMsg(int client, const char[] szMessage, bool isCountdown)
{
	if (!ClientIsValid(client))
		return;

	int duration = isCountdown ? 2 : RoundToNearest(2.5);

	char originalmsg[1024 + 10];
	Format(originalmsg, sizeof(originalmsg), "%s", szMessage);

	int orilen = strlen(originalmsg);

	// 需要从控制台消息中删除这些 Html 符号，并改为替换为新格式.
	ReplaceString(originalmsg, orilen, "<", "&lt;", false);
	ReplaceString(originalmsg, orilen, ">", "&gt;", false);

	// 为邮件添加颜色
	char newmessage[1024 + 10];
	int newlen = strlen(newmessage);

	// 如果消息太长，我们需要减小字体大小.
	if(newlen <= 65)

		// 将颜色放入邮件中(这些 html 格式很好)
		Format(newmessage, sizeof(newmessage), "<span class='fontSize-l'><span color='%s'>%s</span></span>", "#6CFF00", originalmsg);

	else if(newlen <= 100)
		Format(newmessage, sizeof(newmessage), "<span class='fontSize-m'><span color='%s'>%s</span></span>", "#6CFF00", originalmsg);

	else
		Format(newmessage, sizeof(newmessage), "<span class='fontSize-sm'><span color='%s'>%s</span></span>", "#6CFF00", originalmsg);

	// 向玩家发送消息 (https://github.com/Kxnrl/CSGO-HtmlHud/blob/main/fys.huds.sp#L167)
	Event event = CreateEvent("show_survival_respawn_status");
	if (event != null)
	{
		event.SetString("loc_token", newmessage);
		event.SetInt("duration", duration);
		event.SetInt("userid", -1);
		if(client == -1)
		{
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && !IsFakeClient(i))
				{
					event.FireToClient(i);
				}
			}
		}
		else
		{
			event.FireToClient(client);
		}
		event.Cancel();
	}
}