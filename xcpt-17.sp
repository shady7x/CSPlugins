#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define MAXDETECTIONS 4
#define BANTIME 0
#define BANREASON "Aimbot Infraction"

int DATE[] = { 1, 1, 2023 };
bool CHECK_IP = false;
char SERVERS[][] = 
{ 
	"192.168.1.49",
	"192.168.1.50"
};

public Plugin myinfo =
{
	name = "xcpt",
	author = "",
	description = "",
	version = "4.0.0.34",
	url = ""
};

native void SBBanPlayer(int client, int target, int time, char[] reason);
native bool MABanPlayer(int client, int target, int type, int time, char[] reason);

char log_path[PLATFORM_MAX_PATH];

float xd[MAXPLAYERS + 1][10];
float delta[MAXPLAYERS + 1][2];
float pAngs[MAXPLAYERS + 1][2];

int buttons_pl[MAXPLAYERS + 1];
int query_cnt[MAXPLAYERS + 1];
int detections[MAXPLAYERS + 1];

int reason2[MAXPLAYERS + 1];

int exm[MAXPLAYERS + 1][4];
bool log_on[MAXPLAYERS + 1];
bool log_to[MAXPLAYERS + 1];

bool bGoodDate()
{
	char fulldate[11], date[3][5];
	FormatTime(fulldate, sizeof(fulldate), "%d.%m.%Y", GetTime());
	ExplodeString(fulldate, ".", date, sizeof(date), sizeof(date[]));
	
	int day = StringToInt(date[0]);
	int month = StringToInt(date[1]);
	int year = StringToInt(date[2]);
	
	return (year < DATE[2] || (year == DATE[2] && month < DATE[1]) || (year == DATE[2] && month == DATE[1] && day < DATE[0]));
}

bool bGoodIP()
{
	if (!CHECK_IP) return true;
	
	int x = GetConVarInt(FindConVar("hostip"));
	int p[4];
	p[0] = (x >> 24) & 0x000000FF;
	p[1] = (x >> 16) & 0x000000FF;
	p[2] = (x >> 8) & 0x000000FF;
	p[3] = x & 0x000000FF;
	
	for (int i = 0; i < sizeof(SERVERS); ++i)
	{
		char ip[4][4];
		ExplodeString(SERVERS[i], ".", ip, sizeof(ip), sizeof(ip[]));
		if (StringToInt(ip[0]) == p[0] && StringToInt(ip[1]) == p[1] && StringToInt(ip[2]) == p[2] && StringToInt(ip[3]) == p[3])
			return true;
	}

	return false;

}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	BuildPath(Path_SM, log_path, sizeof(log_path), "logs/xcpt.log");
	MarkNativeAsOptional("SBBanPlayer");
	MarkNativeAsOptional("MABanPlayer");
	return APLRes_Success;
}

public void OnPluginStart()
{
	if (bGoodDate() && bGoodIP())
	{
		RegConsoleCmd("ac_log", Command_Log);
		HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	}
}

public void OnClientPutInServer(int client)
{
	xd[client][0] = xd[client][1] = 
	delta[client][0] = delta[client][1] = 
	pAngs[client][0] = pAngs[client][1] =  0.0;
	
	buttons_pl[client] = detections[client] = query_cnt[client] = 
	exm[client][0] = exm[client][1] = 
	exm[client][2] = exm[client][3] = 0;
	
	reason2[client] = 0;
	
	log_on[client] = log_to[client] = false;
}

public void OnMapStart()
{
	log_to[0] = false;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float fVelocity[3], float fAngles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	exm[client][3] = tickcount - exm[client][2];
	
	// 0 - x 1 - y
	xd[client][0] = fAngles[1] - pAngs[client][0];
	xd[client][1] = fAngles[0] - pAngs[client][1];
	
	pAngs[client][0] = fAngles[1];
	pAngs[client][1] = fAngles[0];

	buttons_pl[client] = buttons;
	exm[client][0] = mouse[0];
	exm[client][1] = mouse[1];
	exm[client][2] = tickcount;
	
	return Plugin_Continue;
}

public void Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int u = GetClientOfUserId(GetEventInt(event, "attacker"));
	int v = GetClientOfUserId(GetEventInt(event, "userid")); 
	if (u != v && IsValidClient(u, false, false) && IsValidClient(v, true, true) && !GetEntProp(u, Prop_Send, "m_iFOV"))
	{
		delta[u][0] = xd[u][0];
		delta[u][1] = xd[u][1];
		GetMouseData(u); // and call AnalyzeMouseMovement
	}
}

void AnalyzeMouseMovement(int client)
{
	// moved to .ext
	
	if (detections[client] >= MAXDETECTIONS)
	{
		xcpt_log(client, false, "was banned for using an aimbot");
		xcpt_ban(client);
	}
	
}

int IsBadMouseMovAccel(float data01, float eSens, int exm_cl, float data10_extra, bool check_rage_once)
{
	// moved to .ext
}

int IsBadMouseMovement(float data01, float eSens, bool do_maxspins, bool no_accel, float data10_extra, bool check_rage_once) 
{
	// moved to .ext
}

bool AllAnglesAreBad(float data01, float eSens, int maxspins)
{
	for (int angle_cnt = -maxspins; angle_cnt <= maxspins; ++angle_cnt) // check if spinning but not cheating
	{
		if (!SplitMovementIsBad(data01 + 180 * angle_cnt, eSens))
		{
			return false;
		}
	}
	return true;
}

bool SplitMovementIsBad(float data01, float eSens) // data01 +- 180
{
	// moved to .ext
}

void AimbotDetected(int client, char axis, float data01, float data2, float data3, float data4, float data5, int mode, float c6, float c7, float c8, float c9)
{
	xcpt_log(client, false, "s %f %c.yp %f ft %.0f rw %.0f mode %i c:[%.0f|%f|%f|%.1f] d %f", data2, axis, data3, data4, data5, mode, c6, c7, c8, c9,  data01);
	PrintToServer("s %f %c.yp %f ft %.0f rw %.0f mode %i c:[%.0f|%f|%f|%.1f] d %f", data2, axis, data3, data4, data5, mode, c6, c7, c8, c9,  data01);
	++detections[client];
}

public void ConVar_QueryClient(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, int index)
{
	xd[client][index] = StringToFloat(cvarValue);
	if (result == ConVarQuery_Okay && ++query_cnt[client] == 8) // TODO check if ordering works as intended
	{
		AnalyzeMouseMovement(client);
		query_cnt[client] = 0;	
	}
}

bool IsValidClient(int client, bool bAllowBots, bool bAllowDead)
{
	return (1 <= client <= MaxClients && IsClientInGame(client) && (!IsFakeClient(client) || bAllowBots) && (IsPlayerAlive(client) || bAllowDead));
}

void xcpt_log(int client, bool to_chat, const char[] format, any:...)
{
	char sAuthID[32], line[128];
	GetClientAuthId(client, AuthId_Steam2, sAuthID, sizeof(sAuthID), true);
	VFormat(line, sizeof(line), format, 4);
	if (to_chat)
	{
		for (int i = 1; i <= MAXPLAYERS; ++i)
		{
			if (IsValidClient(i, false, true) && log_to[i])
			{
				PrintToChat(i, "%N (%s) %s", client, sAuthID, line);
			}
		}
		if (log_to[0]) 
		{
			PrintToServer("%N (%s) %s", client, sAuthID, line);
		}
	}
	else
	{
		LogToFileEx(log_path, "%N (%s) %s", client, sAuthID, line);
	}
}

void xcpt_ban(int client)
{
	if (GetFeatureStatus(FeatureType_Native, "SBBanPlayer") == FeatureStatus_Available)
	{
		SBBanPlayer(0, client, BANTIME, BANREASON);
	}
	else if (GetFeatureStatus(FeatureType_Native, "MABanPlayer") == FeatureStatus_Available)
	{
		MABanPlayer(0, client, 1, BANTIME, BANREASON);
	}
	else
	{
		char ip_address[16];
		GetClientIP(client, ip_address, sizeof(ip_address), true);
		ServerCommand("sm_banip %s %i %s", ip_address, BANTIME, BANREASON);
		KickClient(client, BANREASON);
	}
}

public Action Command_Log(int client, int args)
{
	char arg[8];
	GetCmdArg(1, arg, sizeof(arg));
	if (StrEqual("clear", arg, false))
	{
		for (int i = 1; i <= MAXPLAYERS; ++i)
		{
			log_on[i] = false;
			log_to[client] = false;
		}
	}
	else
 	{
 		int id = GetClientOfUserId(StringToInt(arg));
 		if (IsValidClient(id, false, true))
 		{
			if (log_on[id] == false)
			{
				client > 0 ? PrintToChat(client, "%N - enabled", id) : PrintToServer("%N - enabled", id);
				log_on[id] = true;
				log_to[client] = true;
			}
			else
			{
				client > 0 ? PrintToChat(client, "%N - disabled", id) : PrintToServer("%N - disabled", id);
				log_on[id] = false;
				bool all_disabled = true;
				for (int j = 1; j <= MAXPLAYERS; ++j)
				{
					if (log_on[j] == true)
					{
						all_disabled = false;
						break;
					}
				}
				log_to[client] = !all_disabled;
			}
		}
	}
	return Plugin_Handled;
}
