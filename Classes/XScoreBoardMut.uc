class XScoreBoardMut extends Mutator;

var XScoreBoardGameRules sbGameRules;
var xVotingHandler VH;


function PreBeginPlay()
{
    super.PreBeginPlay();
    Level.Game.GameReplicationInfoClass = class'XScoreBoardMut.XScoreBoardGameReplicationInfo';
    SetTimer(0.10, false);
}

function PostBeginPlay()
{
	Level.Game.ScoreBoardType = "XScoreBoardMut.XScoreBoard";
	sbGameRules=Spawn(Class'XScoreBoardMut.XScoreBoardGameRules');
}


function Timer()
{
    local xVotingHandler xVH;

    xVH = xVotingHandler(Level.Game.VotingHandler);
    if(XScoreBoardGameReplicationInfo(Level.Game.GameReplicationInfo) != none)
    {
        if(xVH != none)
        {
            XScoreBoardGameReplicationInfo(Level.Game.GameReplicationInfo).ReplicatedGameConfigAcronym = xVH.GameConfig[xVH.CurrentGameConfig].Acronym;
        }
    }
}

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
	if(Controller(Other)!=None)
		Controller(Other).PlayerReplicationInfoClass = Class'XScoreBoardMut.XScoreBoardPlayerReplicationInfo';
	return true;
}





defaultproperties
{
     bAddToServerPackages=True
     GroupName="KF-XScoreBoardMut"
     FriendlyName="XScoreBoardMut"
     Description="XScoreBoardMut, Show Husk, Scrake, Fleshpound Kill stats and current date, time, votingOption"
     bAlwaysRelevant=True
     RemoteRole=ROLE_SimulatedProxy
}
