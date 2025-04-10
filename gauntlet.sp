#include <sourcemod>
#include <sdktools>
#include <shavit>

ArrayList g_MapList = null;

char g_sCurrentMap[255];
char g_logfile[PLATFORM_MAX_PATH];
int g_iCurrentMapIndex = -1;
int g_iMapSerial = -1;
bool g_bInGauntlet = false;
bool g_bIsLastMap = false;
bool g_bFinishedGauntlet = false;

stylestrings_t gS_StyleStrings[STYLE_LIMIT];
chatstrings_t gS_ChatStrings;

public Plugin myinfo =
{
	name = "bhop gauntlet",
	author = "olivia",
	description = "for aimer <3",
	version = "c:",
	url = "https://KawaiiClan.com"
}

public void OnPluginStart()
{
	g_MapList = new ArrayList(ByteCountToCells(255));
	
	RegConsoleCmd("sm_gauntlet", Command_Gauntlet, "Gauntlet info");
	RegConsoleCmd("sm_startgauntlet", Command_StartGauntlet, "Start the gauntlet");
	RegConsoleCmd("sm_restartgauntlet", Command_StartGauntlet, "Start the gauntlet");
	
	char sDate[64];
	FormatTime(sDate, sizeof(sDate), "%Y-%m-%d", GetTime());
	BuildPath(Path_SM, g_logfile, PLATFORM_MAX_PATH, "logs/gauntlet/%s.txt", sDate);
	
	Shavit_OnChatConfigLoaded();
	Shavit_OnStyleConfigLoaded(Shavit_GetStyleCount());
}

public void Shavit_OnChatConfigLoaded()
{
	Shavit_GetChatStrings(sMessageText, gS_ChatStrings.sText, sizeof(chatstrings_t::sText));
	Shavit_GetChatStrings(sMessageWarning, gS_ChatStrings.sWarning, sizeof(chatstrings_t::sWarning));
	Shavit_GetChatStrings(sMessageVariable, gS_ChatStrings.sVariable, sizeof(chatstrings_t::sVariable));
	Shavit_GetChatStrings(sMessageStyle, gS_ChatStrings.sStyle, sizeof(chatstrings_t::sStyle));
}

public void Shavit_OnStyleConfigLoaded(int styles)
{
	for(int i = 0; i < STYLE_LIMIT; i++)
	{
		if (i < styles)
		{
			Shavit_GetStyleStringsStruct(i, gS_StyleStrings[i]);
		}
	}
}

public void OnMapStart()
{
	GetLowercaseMapName(g_sCurrentMap);
}

public void OnConfigsExecuted()
{
	ReadMapList(g_MapList, g_iMapSerial, "gauntlet");
	if(g_MapList == null)
	{
		LogError("Unable to create a valid map list. Check that 'addons/sourcemod/configs/gauntlet_maplist.ini' exists and there is a 'gauntlet' entry in 'addons/sourcemod/configs/maplists.cfg' pointing to it.");
		PrintToServer("WARNING: Unable to load gauntlet map list. Check SM error logs for more info.");
		Shavit_PrintToChatAll("%sWARNING%s: Unable to load %sgauntlet %smap list. Check SM error logs for more info.", gS_ChatStrings.sWarning, gS_ChatStrings.sText, gS_ChatStrings.sVariable, gS_ChatStrings.sText);
	}
	else
	{
		g_iCurrentMapIndex = g_MapList.FindString(g_sCurrentMap);
		if(g_iCurrentMapIndex != -1)
		{
			g_bInGauntlet = true;
			if(g_iCurrentMapIndex == 0)
			{
				LogToFileEx(g_logfile, "---------- Gauntlet containing %i maps started on map %s ----------", g_MapList.Length, g_sCurrentMap);
			}
			else if(g_iCurrentMapIndex == g_MapList.Length-1)
			{
				g_bIsLastMap = true;
			}
		}
	}
}

public Action Command_Gauntlet(int client, int args)
{
	char sFirstMap[255];
	char sLastMap[255];
	g_MapList.GetString(0, sFirstMap, sizeof(sFirstMap));
	g_MapList.GetString(g_MapList.Length-1, sLastMap, sizeof(sLastMap));
	
	Shavit_PrintToChat(client, "The current map is %s%s%s, which is %s%sin %sthe gauntlet", gS_ChatStrings.sVariable, g_sCurrentMap, gS_ChatStrings.sText, gS_ChatStrings.sVariable, g_bInGauntlet?"":"not ", gS_ChatStrings.sText);
	Shavit_PrintToChat(client, "Starting map: %s%s%s - Ending map: %s%s", gS_ChatStrings.sVariable, sFirstMap, gS_ChatStrings.sText, gS_ChatStrings.sVariable, sLastMap);
	Shavit_PrintToChat(client, "Total maps: %i", g_MapList.Length);
	Shavit_PrintToChat(client, "Type %s!startgauntlet %sto start a new gauntlet run", gS_ChatStrings.sVariable, gS_ChatStrings.sText);
	return Plugin_Handled;
}

public Action Command_StartGauntlet(int client, int args)
{
	char sFirstMap[255];
	g_MapList.GetString(0, sFirstMap, sizeof(sFirstMap));
	ForceChangeLevel(sFirstMap, "Gauntlet starting");
	return Plugin_Handled;
}

public Action Shavit_OnFinishMessage(int client, bool &everyone, timer_snapshot_t snapshot, int overwrite, int rank, char[] message, int maxlen)
{
	if(g_bInGauntlet && !g_bFinishedGauntlet && snapshot.iTimerTrack == 0)
	{
		int iSteamID = GetSteamAccountID(client);
		char sTime[32];
		char sMapTime[32];
		
		FloatToString(snapshot.fCurrentTime, sTime, sizeof(sTime));
		FloatToString(GetGameTime(), sMapTime, sizeof(sMapTime));
		
		LogToFileEx(g_logfile, "%N [U:1:%i] finished %s in %s (%s) [%s spent on map]", client, iSteamID, g_sCurrentMap, FormatToSeconds(sTime), gS_StyleStrings[Shavit_GetBhopStyle(client)].sStyleName, FormatToSeconds(sMapTime));
		
		if(g_bIsLastMap)
		{
			if(!g_bFinishedGauntlet)
			{
				LogToFileEx(g_logfile, "---------- Gauntlet completed! ----------");
				Shavit_PrintToChat(client, "Gauntlet %scompleted%s! Nice job!!!", gS_ChatStrings.sVariable, gS_ChatStrings.sText);
				Shavit_PrintToChat(client, "Check %saddons/sourcemod/logs/gauntlet %sfor your times!", gS_ChatStrings.sVariable, gS_ChatStrings.sText);
				g_bFinishedGauntlet = true;
			}
		}
		else
		{
			char sNextMap[255];
			g_MapList.GetString(g_iCurrentMapIndex+1, sNextMap, sizeof(sNextMap));
			Shavit_PrintToChat(client, "Gauntlet map %scompleted%s! Going to next map %s%s%s...", gS_ChatStrings.sVariable, gS_ChatStrings.sText, gS_ChatStrings.sVariable, sNextMap, gS_ChatStrings.sText);
			ForceChangeLevel(sNextMap, "Gauntlet progressing");
		}
	}
	return Plugin_Continue;
}

char[] FormatToSeconds(char time[32])
{
	int iTemp = RoundToFloor(StringToFloat(time));
	int iHours = 0;

	if(iTemp > 3600)
	{
		iHours = iTemp / 3600;
		iTemp %= 3600;
	}

	int iMinutes = 0;

	if(iTemp >= 60)
	{
		iMinutes = iTemp / 60;
		iTemp %= 60;
	}

	float fSeconds = iTemp + StringToFloat(time) - RoundToFloor(StringToFloat(time));
	char result[32];
	
	if (iHours > 0)
	{
		Format(result, sizeof(result), "%ih %im %.3fs", iHours, iMinutes, fSeconds);
	}
	else if(iMinutes > 0)
	{
		Format(result, sizeof(result), "%im %.3fs", iMinutes, fSeconds);
	}
	else
	{
		Format(result, sizeof(result), "%.3fs", fSeconds);
	}
	
	return result;
}