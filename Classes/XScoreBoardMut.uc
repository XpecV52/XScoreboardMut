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
     GroupName="KF-XScoreBoard"
     FriendlyName="XScoreBoardMut"
     Description="XScoreBoardMut V2 by The0neThe0nly; Show Husk, Scrake, Fleshpound Kill stats; Show current Date, Time, votingOption; Replace custom Perkicons; Remove perk level star and replace it to pure digit."
     bAlwaysRelevant=True
     RemoteRole=ROLE_SimulatedProxy
}
