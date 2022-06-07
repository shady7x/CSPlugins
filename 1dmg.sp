#pragma semicolon 1
#pragma newdecls required

#include <sdkhooks>

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	PrintToChat(attacker, "%.0f", damage);
	damage = 1.0;
	return Plugin_Changed;
}