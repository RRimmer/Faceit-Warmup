#pragma semicolon 1
#pragma newdecls required

#include sdktools_gamerules

int iWeaponParent, iStartMoney, iTimeDelete;
Handle hTimer;
ConVar cvStartMoney, cvTimeDelete, cvGotMoney;
bool bGotMoney;

public Plugin myinfo    =
{
    name                    = "Faceit Warmup",
    author                = "Paranoiiik, Grey83, Palonez, TechKnow, Rimmer",
    description            = "Faceit Warmup",
    version                = "1.0.1",
    url                    = "https://hlmod.ru/resources/faceit-warmup.3929/"
};

public void OnPluginStart()
{
    iWeaponParent = FindSendPropInfo("CBaseCombatWeapon", "m_hOwnerEntity");
 
    HookEvent("round_start", eventRoundStart);
    HookEventEx("player_spawn", eventPlayerSpawn, EventHookMode_Pre);
    HookEvent("item_purchase", ItemBuy, EventHookMode_Post);
 
    AutoExecConfig(true, "FaceitWarmup");
 
    HookConVarChange((cvStartMoney = CreateConVar("sm_fw_start_money", "16000", "Кол-во устанавливаемых денег на разминке")), OnCVChanged);
    iStartMoney = cvStartMoney.IntValue;
 
    HookConVarChange((cvTimeDelete = CreateConVar("sm_fw_time_delete", "1", "Каждые N секунд удалять выпавшее оружие")), OnCVChanged);
    iTimeDelete = cvTimeDelete.IntValue;
 
    HookConVarChange((cvGotMoney = CreateConVar("sm_fw_got_money", "1", "Способ установки денег [0 - после покупки | 1 - после спавна]")), OnCVChanged);
    bGotMoney = cvGotMoney.BoolValue;
}

public void OnCVChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if(convar != INVALID_HANDLE)
    {
        if(convar == cvStartMoney) iStartMoney = convar.IntValue;
        else if(convar == cvTimeDelete) iTimeDelete = convar.IntValue;
        else if(convar == cvGotMoney) bGotMoney  = convar.BoolValue;
    }
}

public void eventRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    SetConVarInt(FindConVar("mp_weapons_allow_typecount"), GameRules_GetProp("m_bWarmupPeriod") ? -1 : 2);
}

public void ItemBuy(Event event, const char[] name, bool dontBroadcast)
{
    static int client;
    if(GameRules_GetProp("m_bWarmupPeriod") != 0 && (client = GetClientOfUserId(event.GetInt("userid"))) && GetClientTeam(client) > 1 && !bGotMoney) SetEntProp(client, Prop_Send, "m_iAccount", iStartMoney);
}

public void eventPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    static int client;
    if(GameRules_GetProp("m_bWarmupPeriod") != 0 && (client = GetClientOfUserId(event.GetInt("userid"))) && GetClientTeam(client) > 1 && bGotMoney) SetEntProp(client, Prop_Send, "m_iAccount", iStartMoney);
}

public void OnMapStart()
{
    hTimer = CreateTimer(float(iTimeDelete), timerXUY, _, TIMER_REPEAT);
}

Action timerXUY(Handle timer)
{
    if(GameRules_GetProp("m_bWarmupPeriod") != 0)
    {
        int iMaxEntities = GetMaxEntities();
        char sWeapon[64];

        for(int i = MaxClients; i < iMaxEntities; i++)
        {
            if(IsValidEdict(i) && IsValidEntity(i))
            {
                GetEdictClassname(i, sWeapon, sizeof sWeapon);
                if((StrContains(sWeapon,  "weapon_") != -1 || StrContains(sWeapon, "item_") != -1) && GetEntDataEnt2(i, iWeaponParent) == -1) RemoveEdict(i);
            }
        }
    }
 
    return Plugin_Continue;
}

public void OnMapEnd()
{
    delete hTimer;
}