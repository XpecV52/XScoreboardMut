class XScoreBoardGameReplicationInfo extends KFSGameReplicationInfo;

var transient string ReplicatedGameConfigAcronym;


replication
{
    reliable if(bNetDirty && Role == ROLE_Authority)
        ReplicatedGameConfigAcronym;
}