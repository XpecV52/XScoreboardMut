class XScoreBoardGameRules extends GameRules;

function PostBeginPlay()
{
	if( Level.Game.GameRulesModifiers==None )
		Level.Game.GameRulesModifiers = Self;
	else Level.Game.GameRulesModifiers.AddGameRules(Self);
}

function AddGameRules(GameRules GR)
{
	if ( GR!=Self )
		Super.AddGameRules(GR);
}

function bool PreventDeath(Pawn Killed, Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
	if(DamageType==None || Killer==None || Killed==None)
	{
		if ( NextGameRules != None) 
			return NextGameRules.PreventDeath(Killed,Killer,DamageType,HitLocation);
		return false;
	}
	if	(
			Killed.IsA('ZombieFleshpound')
			&&	Killer!=none
			&&	XScoreBoardPlayerReplicationInfo(Killer.PlayerReplicationInfo)!=none
		)
	{
		++XScoreBoardPlayerReplicationInfo(Killer.PlayerReplicationInfo).FPKilled;
	}
	
	if	(
			Killed.IsA('ZombieScrake')
			&&	Killer!=none
			&&	XScoreBoardPlayerReplicationInfo(Killer.PlayerReplicationInfo)!=none
		)
	{
		++XScoreBoardPlayerReplicationInfo(Killer.PlayerReplicationInfo).SCKilled;
	}
	
	if	(
			Killed.IsA('ZombieHusk')
			&&	Killer!=none
			&&	XScoreBoardPlayerReplicationInfo(Killer.PlayerReplicationInfo)!=none
		)
	{
		++XScoreBoardPlayerReplicationInfo(Killer.PlayerReplicationInfo).HuskKilled;
	}

	if(NextGameRules != None) 
		return NextGameRules.PreventDeath(Killed,Killer, damageType,HitLocation);
	return false;
}

//Тут информацию по урону собираем
function int NetDamage(int OriginalDamage, int Damage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	if ( NextGameRules != None) 
		return NextGameRules.NetDamage(OriginalDamage, Damage, injured, instigatedBy, HitLocation, Momentum, DamageType);
	return Damage;
}

defaultproperties
{
}
