#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "xhop",
	author = "",
	description = "",
	version = "1.0.2",
	url = ""
};

char log_path[PLATFORM_MAX_PATH];

bool bInAir_lasttick[MAXPLAYERS + 1];
int iPerfect_starttick[MAXPLAYERS + 1];

float fPerfectionRate[MAXPLAYERS + 1];
int iPerfectJumps[MAXPLAYERS + 1];
int iNotPerfectJumps[MAXPLAYERS + 1];

public OnPluginStart()
{
	BuildPath(Path_SM, log_path, sizeof(log_path), "logs/xhop.log");
	PrintToServer("xhop -> loaded");
}

public OnClientPutInServer(int client)
{
	bInAir_lasttick[client] = false;
	iPerfect_starttick[client] = -1;
	ResetJumps(client);
}

void ResetJumps(int client)
{
	iPerfectJumps[client] = iNotPerfectJumps[client] = 0;
	fPerfectionRate[client] = 0.0;
}

public Action:OnPlayerRunCmd(int client, int &buttons, int &impulse, float fVelocity[3], float fAngles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsValidClient(client, false, false))
	{
		if (GetEntityFlags(client) & 1) // on ground
		{
			if (bInAir_lasttick[client])
				iPerfect_starttick[client] = tickcount;
			bInAir_lasttick[client] = false;
		}
		else // in air
		{
			if (iPerfect_starttick[client] == tickcount - 1)
			{
				++iPerfectJumps[client];
			}
			else if (!bInAir_lasttick[client])
			{
				int gap = tickcount - iPerfect_starttick[client];
				if (gap > 0 && gap < 10)
				{
					++iNotPerfectJumps[client];
				}
			}
			int iTotalJumps = iPerfectJumps[client] + iNotPerfectJumps[client];
			if (iTotalJumps >= 12) 
			{
				fPerfectionRate[client] = 100.0 / float(iTotalJumps) * float(iPerfectJumps[client]);
				if (fPerfectionRate[client] > 70.0)
				{
					xhop_log(client, "Perfection rate: %.2f%% (0.%i)", fPerfectionRate[client], iTotalJumps);
				}
				ResetJumps(client);
			}
			bInAir_lasttick[client] = true;
		}
	}
	return Plugin_Continue;
}

void xhop_log(int client, const char[] format, any:...) 
{
	char sAuthID[32], line[128];
	if (!GetClientAuthId(client, AuthId_Steam2, sAuthID, sizeof(sAuthID), true))
		strcopy(sAuthID, sizeof(sAuthID), "-");
	VFormat(line, sizeof(line), format, 3);
	LogToFileEx(log_path, "%N (%s) %s", client, sAuthID, line);
}

bool IsValidClient(int client, bool bAllowBots, bool bAllowDead)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)))
		return false;
	return true;
}