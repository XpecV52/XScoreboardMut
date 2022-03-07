class XScoreBoardPlayerReplicationInfo extends KFPlayerReplicationInfo;

var int FPKilled;
var int SCKilled;
var int HuskKilled;

replication
{
	reliable if (bNetDirty && Role == Role_Authority)
		FPKilled,SCKilled,HuskKilled;
}

defaultproperties
{
}
