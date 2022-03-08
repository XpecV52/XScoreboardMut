class XScoreBoard extends KFScoreBoardNew;


#exec OBJ LOAD FILE="X_VetIcon.utx" Package="XScoreBoardMut"

var localized string FPText,SCText,HuskText, KillAssistsSeparator;
var localized string NotShownInfo,PlayerCountText,SpectatorCountText,AliveCountText,BotText;
var Color WhiteColor,GrayColor,DarkGrayColor,DodgerBlueColor,YellowColor,OrangeColor,OrangeRedColor;

struct ColorRecord
{
    var string Color;
    var string Tag;
    var string RGB;
};
var config array<ColorRecord> ColorList;
var array<string> colorCodes;
var bool bMadeColorCodes;
var string PN;

function string GetDateString()
{
    local string DateString;

    DateString = "Date:";
    switch(Level.DayOfWeek)
    {
        case 0:
            DateString @= "Sunday";
            break;
        case 1:
            DateString @= "Monday";
            break;
        case 2:
            DateString @= "Tuesday";
            break;
        case 3:
            DateString @= "Wednesday";
            break;
        case 4:
            DateString @= "Thursday";
            break;
        case 5:
            DateString @= "Friday";
            break;
        case 6:
            DateString @= "Saturday";
            break;
        default:
            break;
    }//sat | 09M-10D-2020Y | 15:
    //Year
    DateString @= ("|" $ string(Level.Year));
    //Mon
    if(Level.Month < 10)
        DateString $= ("/" $ "0" $ string(Level.Month));
    else
        DateString $= ("/" $ string(Level.Month));
        
    //Day
    if(Level.Day < 10)
        DateString $= ("/" $ "0" $ string(Level.Day));
    else
        DateString $= ("/" $ string(Level.Day));
        
    //Time
    if(Level.Hour < 10)
        DateString @= ("|" @ "0" $ string(Level.Hour));
    else
        DateString @= ("|" @ string(Level.Hour));
    if(Level.Minute < 10)
        DateString $= (":" $ "0" $ string(Level.Minute));
    else
        DateString $= (":" $ string(Level.Minute));
    if(Level.Second < 10)
        DateString $= (":" $ "0" $ string(Level.Second));
    else
        DateString $= (":" $ string(Level.Second));
    return DateString;
}

function string GetGameDifficulty()
{   
    switch(KFGameReplicationInfo(Level.GRI).GameDiff)
    {
        case 1:
            return "Noob";
            break;
        case 2:
            return "Normal";
            break;
        case 4:
            return "Hard";
            break;
        case 5:
            return "Suicidal";
            break;
        case 7:
            return "Infernal";
            break;
        default:
            return "Null";
            break;
    }
}


function string GetGameAcronym()
{
	if(GRI != none && XScoreBoardGameReplicationInfo(GRI).ReplicatedGameConfigAcronym != "")
    {
		return XScoreBoardGameReplicationInfo(GRI).ReplicatedGameConfigAcronym;
    }
    else if(GRI != none)
	{
		return "DEFAULT";
	}
}



function DrawTitle(Canvas Canvas, float HeaderOffsetY, float PlayerAreaY, float PlayerBoxSizeY)
{
    local string CurrentGameString, CurrentDateString, CurrentDiffString, CurrentVoteString, ScoreInfoString, RestartString;
    local float CurrentGameXL, CurrentGameYL, CurrentDateXL, CurrentDateYL, ScoreInfoXL, ScoreInfoYL,
	    TitleYPos, DrawYPos;
	local Font CF;

	CurrentVoteString = GetGameAcronym();
	CurrentDiffString = GetGameDifficulty();
    CurrentDateString = GetDateString();
    CurrentGameString = "Game:" @ CurrentVoteString$"-"$CurrentDiffString @ "|" @ WaveString @ string(InvasionGameReplicationInfo(GRI).WaveNumber + 1)$"/"$string(InvasionGameReplicationInfo(GRI).FinalWave) @ "|" @ Level.Title;
    CF = Canvas.Font;
	Canvas.FontScaleX = 1.0;
	Canvas.FontScaleY = 1.0;
    Canvas.Font = class'ROHud'.static.GetSmallMenuFont(Canvas);
    if(GRI.TimeLimit != 0)
    {
        ScoreInfoString = TimeLimit $ (FormatTime(GRI.RemainingTime));
    }
    else
    {
        ScoreInfoString = FooterText @ (FormatTime(GRI.ElapsedTime));
    }
    if(UnrealPlayer(Owner).bDisplayLoser)
    {
        ScoreInfoString = class'HudBase'.default.YouveLostTheMatch;
    }
    else
    {
        if(UnrealPlayer(Owner).bDisplayWinner)
        {
            ScoreInfoString = class'HudBase'.default.YouveWonTheMatch;
        }
        else
        {
            if(PlayerController(Owner).IsDead())
            {
                RestartString = Restart;
                if(PlayerController(Owner).PlayerReplicationInfo.bOutOfLives)
                {
                    RestartString = OutFireText;
                }
                ScoreInfoString = RestartString;
            }
        }
    }
    TitleYPos = Canvas.ClipY * 0.130;
    DrawYPos = TitleYPos;
    Canvas.DrawColor = HudClass.default.WhiteColor;
    Canvas.StrLen(CurrentGameString, CurrentGameXL, CurrentGameYL);
    Canvas.SetPos(0.50 * (Canvas.ClipX - CurrentGameXL), DrawYPos);
    Canvas.DrawText(CurrentGameString);
    DrawYPos += CurrentGameYL;
    Canvas.StrLen(CurrentDateString, CurrentDateXL, CurrentDateYL);
    Canvas.SetPos(0.50 * (Canvas.ClipX - CurrentDateXL), DrawYPos);
    Canvas.DrawText(CurrentDateString);
    DrawYPos += CurrentDateYL;
    Canvas.StrLen(ScoreInfoString, ScoreInfoXL, ScoreInfoYL);
    Canvas.SetPos(0.50 * (Canvas.ClipX - ScoreInfoXL), DrawYPos);
    Canvas.DrawText(ScoreInfoString);
}

simulated event UpdateScoreBoard(Canvas Canvas)
{
	local PlayerReplicationInfo PRI, OwnerPRI;
	local int i,j, FontReduction, NetXPos, PlayerCount, HeaderOffsetY, HeadFoot, MessageFoot, PlayerBoxSizeY, BoxSpaceY, NameXPos, BoxTextOffsetY, OwnerOffset, HealthXPos, BoxXPos,KillsXPos, TitleYPos, BoxWidth, VetXPos, TempVetXPos, VetYPos, NotShownCount;
	local float XL,YL, MaxScaling;
	local float deathsXL, AssistsXL, KillsXL, netXL,HealthXL,  KillWidthX, HealthWidthX, TimeXL, TimeWidthX, TimeXPos, ScoreXPos, ScoreXL;
	local float SCXL, SCWidthx, SCXPos, FPXL, FPWidthx, FPXPos, HuskXL, HuskWidthx, HuskXPos;
	local bool bNameFontReduction;
	local Material VeterancyBox, StarMaterial;
	local int TempLevel;
	local string PlayerTime;
	local KFPlayerReplicationInfo KFPRI;
	local XScoreBoardPlayerReplicationInfo SBKFPRI;
	local float AssistsXPos,AssistsWidthX;
	local float CashX;
	local string CashString,HealthString;
	local float OutX;
	local array<PlayerReplicationInfo> TeamPRIArray;
	
	OwnerPRI = KFPlayerController(Owner).PlayerReplicationInfo;
	OwnerOffset = -1;

	for (i = 0; i < GRI.PRIArray.Length; i++)
	{
		PRI = GRI.PRIArray[i];

		if ( !PRI.bOnlySpectator )
		{
		    if( !PRI.bOutOfLives && KFPlayerReplicationInfo(PRI).PlayerHealth>0 )
				++HeadFoot;
			if ( PRI == OwnerPRI )
				OwnerOffset = i;

			PlayerCount++;
			TeamPRIArray[ TeamPRIArray.Length ] = PRI;
		}
		else ++NetXPos;
	}


	PlayerCount = Min(PlayerCount, MAXPLAYERS);

	Canvas.Font = class'ROHud'.static.GetSmallMenuFont(Canvas);
	Canvas.StrLen("Test", XL, YL);
	BoxSpaceY = 0.25 * YL;
	PlayerBoxSizeY = 1.2 * YL;
	HeadFoot = 7 * YL;
	MessageFoot = 1.5 * HeadFoot;

	if ( PlayerCount > (Canvas.ClipY - 1.5 * HeadFoot) / (PlayerBoxSizeY + BoxSpaceY) )
	{
		BoxSpaceY = 0.125 * YL;
		PlayerBoxSizeY = 1.25 * YL;

		if ( PlayerCount > (Canvas.ClipY - 1.5 * HeadFoot) / (PlayerBoxSizeY + BoxSpaceY) )
		{
			if ( PlayerCount > (Canvas.ClipY - 1.5 * HeadFoot) / (PlayerBoxSizeY + BoxSpaceY) )
			{
				PlayerBoxSizeY = 1.125 * YL;
			}
		}
	}
	

	if (Canvas.ClipX < 512)
		PlayerCount = Min(PlayerCount, 1+(Canvas.ClipY - HeadFoot) / (PlayerBoxSizeY + BoxSpaceY) );
	else
		PlayerCount = Min(PlayerCount, (Canvas.ClipY - HeadFoot) / (PlayerBoxSizeY + BoxSpaceY) );

	if (FontReduction > 2) 
		MaxScaling = 2;
	else
		MaxScaling = 2; 

	PlayerBoxSizeY = FClamp((1.25 + (Canvas.ClipY - 0.67 * MessageFoot)) / PlayerCount - BoxSpaceY, PlayerBoxSizeY, MaxScaling * YL);

	bDisplayMessages = (PlayerCount <= (Canvas.ClipY - MessageFoot) / (PlayerBoxSizeY + BoxSpaceY));

	while( ((PlayerBoxSizeY+BoxSpaceY)*PlayerCount)>(Canvas.ClipY-HeaderOffsetY) )
	{
		if( ++i>=5 || ++FontReduction>=3 ) // Shrink font, if too small then break loop.
		{
			// We need to remove some player names here to make it fit.
			NotShownCount = PlayerCount-int((Canvas.ClipY-HeaderOffsetY)/(PlayerBoxSizeY+BoxSpaceY))+1;
			PlayerCount-=NotShownCount;
			break;
		}
		Canvas.Font = class'ROHud'.static.LoadMenuFontStatic(i);
		Canvas.TextSize("Test", XL, YL);
		PlayerBoxSizeY = 1.2 * YL;
		BoxSpaceY = 0.25 * YL;
	}
	
	HeaderOffsetY = 8.5 * YL;
	BoxWidth = 0.7 * Canvas.ClipX;
	BoxXPos = 0.2* (Canvas.ClipX - BoxWidth);
	BoxWidth = Canvas.ClipX - 2 * BoxXPos;
	VetXPos = BoxXPos + 0.00004 * BoxWidth;
	NameXPos = BoxXPos + 0.0735 * BoxWidth;//0.085
	//Flame
	KillsXPos = BoxXPos + 0.33 * BoxWidth; //0.50 * BoxWidth;
	AssistsXPos = BoxXPos + 0.365 * BoxWidth; 
	HuskXPos = BoxXPos + 0.455 * BoxWidth;
	SCXPos = BoxXPos + 0.545 * BoxWidth;
    FPXPos = BoxXPos + 0.635 * BoxWidth;
	ScoreXPos = BoxXPos + 0.725 * BoxWidth; 
	TimeXPos = BoxXPos + 0.815 * BoxWidth; 
    HealthXpos = BoxXPos + 0.895 * BoxWidth; 
	NetXPos = BoxXPos + 0.966* BoxWidth;  
	//


	// Draw background boxes
	Canvas.Style = ERenderStyle.STY_Alpha;
    Canvas.DrawColor.R = 0;
    Canvas.DrawColor.G = 100;
    Canvas.DrawColor.B = byte(255);
	Canvas.DrawColor.A = 128;

	for (i = 0; i < PlayerCount; i++)
	{
		Canvas.SetPos(BoxXPos, HeaderOffsetY + (PlayerBoxSizeY + BoxSpaceY) * i);
		Canvas.DrawTileStretched(BoxMaterial, BoxWidth, PlayerBoxSizeY);
	}
	if( NotShownCount>0 ) // Add box for not shown players.
	{
		Canvas.DrawColor = HUDClass.default.RedColor;
		Canvas.SetPos(BoxXPos, HeaderOffsetY + (PlayerBoxSizeY + BoxSpaceY) * PlayerCount);
		Canvas.DrawTileStretched( BoxMaterial, BoxWidth, PlayerBoxSizeY);
		Canvas.DrawColor =default.DodgerBlueColor;
	}

	// Draw headers
    DrawTitle(Canvas, HeaderOffsetY, (PlayerCount + 1) * (PlayerBoxSizeY + BoxSpaceY), PlayerBoxSizeY);
	TitleYPos = HeaderOffsetY - 1.1 * YL;
	Canvas.StrLen(HealthText, HealthXL, YL);
	Canvas.StrLen(DeathsText, DeathsXL, YL);
	Canvas.StrLen(AssistsHeaderText, AssistsXL, YL);
	Canvas.StrLen(KillsText, KillsXL, YL);
	//Flame
	Canvas.StrLen(FPText, FPXL, YL);
	Canvas.StrLen(SCText, SCXL, YL);
    Canvas.StrLen(HuskText,HuskXL,YL);
	//
	Canvas.StrLen(PointsText, ScoreXL, YL);
	Canvas.StrLen(TimeText, TimeXL, YL);
	Canvas.StrLen(NetText, NetXL, YL);
	Canvas.StrLen("INJURED", HealthWidthX, YL);

	Canvas.DrawColor = HudClass.default.WhiteColor;
	Canvas.SetPos(NameXPos, TitleYPos);
	Canvas.DrawText(PlayerText,true);

	Canvas.DrawColor = HudClass.default.WhiteColor;
	Canvas.SetPos(KillsXPos - 0.5 * KillsXL, TitleYPos);
	Canvas.DrawText(KillsText,true);
    
	// Draw text assists
	Canvas.DrawColor = default.DarkGrayColor;
	Canvas.SetPos(AssistsXPos - 0.5 * AssistsXL, TitleYPos);
	Canvas.DrawText(KillAssistsSeparator $ AssistsHeaderText,true);
	//Flame
	Canvas.DrawColor = HudClass.default.RedColor;
	Canvas.SetPos(FPXPos - 0.5 * FPXL, TitleYPos);
	Canvas.DrawText(FPText,true);
	
	Canvas.DrawColor = default.OrangeColor;
	Canvas.SetPos(SCXPos - 0.5 * SCXL, TitleYPos);
	Canvas.DrawText(SCText,true);
	//
	Canvas.DrawColor = default.OrangeRedColor;
    Canvas.SetPos(HuskXPos - 0.5 * HuskXL,TitleYPos);
    Canvas.DrawText(HuskText,true);

	Canvas.DrawColor = HudClass.default.WhiteColor;
	Canvas.SetPos(ScoreXPos - 0.5 * ScoreXL, TitleYPos);
	Canvas.DrawText(PointsText,true);
	
	Canvas.DrawColor = HudClass.default.WhiteColor;
	Canvas.SetPos(TimeXPos - 0.5 * TimeXL, TitleYPos);
	Canvas.DrawText(TimeText,true);

	Canvas.DrawColor = HudClass.default.WhiteColor;
	Canvas.SetPos(HealthXPos - 0.5 * HealthXL, TitleYPos);
	Canvas.DrawText(HealthText,true);
	
	Canvas.DrawColor = HudClass.default.WhiteColor;
	Canvas.SetPos(NetXPos - 0.5 * NetXL, TitleYPos);
	Canvas.DrawText(NetText,true);

	// Draw player names
	Canvas.DrawColor = default.DodgerBlueColor;
	for (i = 0; i < PlayerCount; i++)
	{	
		PN = ParseTags(TeamPRIArray[i].PlayerName);
		Canvas.StrLen(PN, XL, YL);

	}

	if ( bNameFontReduction )
		Canvas.Font = GetSmallerFontFor(Canvas, FontReduction - 1);

	Canvas.Style = ERenderStyle.STY_Alpha;
	Canvas.DrawColor = HUDClass.default.WhiteColor;
	Canvas.SetPos(0.5 * Canvas.ClipX, HeaderOffsetY + 4);
	BoxTextOffsetY = HeaderOffsetY + 0.5 * (PlayerBoxSizeY - YL);

	Canvas.DrawColor = HUDClass.default.WhiteColor;

	for (i = 0; i < PlayerCount; i++)
	{
		Canvas.SetPos(NameXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY);

		if( i == OwnerOffset )
		{
			Canvas.DrawColor.R = 255;
			Canvas.DrawColor.G = 191;
			Canvas.DrawColor.B = 1;
		}
		else
		{
			Canvas.DrawColor.R = 255;
			Canvas.DrawColor.G = 255;
			Canvas.DrawColor.B = 255;
		}

		PN = ParseTags(TeamPRIArray[i].PlayerName);
		Canvas.DrawTextClipped(PN);
	}

	if( NotShownCount>0 ) // Draw not shown info
	{
		Canvas.DrawColor.G = 255;
		Canvas.DrawColor.B = 1;
		Canvas.SetPos(NameXPos, (PlayerBoxSizeY + BoxSpaceY)*PlayerCount + BoxTextOffsetY);
		Canvas.DrawText(NotShownCount@NotShownInfo,true);
	}
	Canvas.DrawColor = HUDClass.default.WhiteColor;

	if (bNameFontReduction)
		Canvas.Font = GetSmallerFontFor(Canvas, FontReduction);

	Canvas.Style = ERenderStyle.STY_Normal;
	MaxScaling = FMax(PlayerBoxSizeY, 30.f);

	// Draw each player's information
	for (i = 0; i < PlayerCount; i++)
	{
		KFPRI = KFPlayerReplicationInfo(TeamPRIArray[i]) ;
		SBKFPRI = XScoreBoardPlayerReplicationInfo(KFPRI);
		Canvas.DrawColor = HUDClass.default.WhiteColor;

		// Display perks.
		if ( KFPRI!=None && KFPRI.ClientVeteranSkill != none )
		{
			if(KFPRI.ClientVeteranSkillLevel == 6)
			{	
				if(KFPRI.ClientVeteranSkill == class'KFVetBerserker')
				{
					VeterancyBox = Texture'XScoreBoardMut.perk_zerker_b';
					StarMaterial = None;
					TempLevel = KFPRI.ClientVeteranSkillLevel;
				}
				if(KFPRI.ClientVeteranSkill == class'KFVetCommando')
				{
					VeterancyBox = Texture'XScoreBoardMut.perk_commando_b';
					StarMaterial = None;
					TempLevel = KFPRI.ClientVeteranSkillLevel;
				}
				if(KFPRI.ClientVeteranSkill == class'KFVetDemolitions')
				{
					VeterancyBox = Texture'XScoreBoardMut.perk_demo_b';
					StarMaterial = None;
					TempLevel = KFPRI.ClientVeteranSkillLevel;
				}
				if(KFPRI.ClientVeteranSkill == class'KFVetFieldMedic')
				{
					VeterancyBox = Texture'XScoreBoardMut.perk_medic_b';
					StarMaterial = None;
					TempLevel = KFPRI.ClientVeteranSkillLevel;
				}
				if(KFPRI.ClientVeteranSkill == class'KFVetFirebug')
				{
					VeterancyBox = Texture'XScoreBoardMut.perk_fire_b';
					StarMaterial = None;
					TempLevel = KFPRI.ClientVeteranSkillLevel;
				}
				if(KFPRI.ClientVeteranSkill == class'KFVetSharpshooter')
				{
					VeterancyBox = Texture'XScoreBoardMut.perk_sharp_b';
					StarMaterial = None;
					TempLevel = KFPRI.ClientVeteranSkillLevel;
				}
				if(KFPRI.ClientVeteranSkill == class'KFVetSupportSpec')
				{
					VeterancyBox = Texture'XScoreBoardMut.perk_support_b';
					StarMaterial = None;
					TempLevel = KFPRI.ClientVeteranSkillLevel;
				}
			}
			else
			{	
				if(KFPRI.ClientVeteranSkill == class'KFVetBerserker')
				{
					VeterancyBox = Texture'XScoreBoardMut.perk_zerker_a';
					StarMaterial = None;
					TempLevel = KFPRI.ClientVeteranSkillLevel;
				}
				if(KFPRI.ClientVeteranSkill == class'KFVetCommando')
				{
					VeterancyBox = Texture'XScoreBoardMut.perk_commando_a';
					StarMaterial = None;
					TempLevel = KFPRI.ClientVeteranSkillLevel;
				}
				if(KFPRI.ClientVeteranSkill == class'KFVetDemolitions')
				{
					VeterancyBox = Texture'XScoreBoardMut.perk_demo_a';
					StarMaterial = None;
					TempLevel = KFPRI.ClientVeteranSkillLevel;
				}
				if(KFPRI.ClientVeteranSkill == class'KFVetFieldMedic')
				{
					VeterancyBox = Texture'XScoreBoardMut.perk_medic_a';
					StarMaterial = None;
					TempLevel = KFPRI.ClientVeteranSkillLevel;
				}
				if(KFPRI.ClientVeteranSkill == class'KFVetFirebug')
				{
					VeterancyBox = Texture'XScoreBoardMut.perk_fire_a';
					StarMaterial = None;
					TempLevel = KFPRI.ClientVeteranSkillLevel;
				}
				if(KFPRI.ClientVeteranSkill == class'KFVetSharpshooter')
				{
					VeterancyBox = Texture'XScoreBoardMut.perk_sharp_a';
					StarMaterial = None;
					TempLevel = KFPRI.ClientVeteranSkillLevel;
				}
				if(KFPRI.ClientVeteranSkill == class'KFVetSupportSpec')
				{
					VeterancyBox = Texture'XScoreBoardMut.perk_support_a';
					StarMaterial = None;
					TempLevel = KFPRI.ClientVeteranSkillLevel;
				}
			}

			if ( VeterancyBox != None )
			{
				TempVetXPos = VetXPos;
				VetYPos = (PlayerBoxSizeY + BoxSpaceY) * i + BoxTextOffsetY - PlayerBoxSizeY * 0.22;
				Canvas.SetPos(TempVetXPos, VetYPos);
				Canvas.DrawTile(VeterancyBox, PlayerBoxSizeY, PlayerBoxSizeY, 0, 0, VeterancyBox.MaterialUSize(), VeterancyBox.MaterialVSize());

				TempVetXPos += PlayerBoxSizeY - ((PlayerBoxSizeY/5) * 0.75);
				VetYPos += PlayerBoxSizeY - ((PlayerBoxSizeY/5) * 1.5);

				Canvas.SetPos(TempVetXPos, VetYPos-(PlayerBoxSizeY/5) * 0.7);
				Canvas.DrawText(TempLevel);
				VetYPos -= (PlayerBoxSizeY/5) * 0.7;
			}
		}


		// draw kills
		if( bDisplayWithKills )
		{
       		Canvas.DrawColor = HUDClass.default.WhiteColor;
			Canvas.StrLen(KFPRI.Kills, KillWidthX, YL);
			Canvas.SetPos(KillsXPos - 0.5 * KillWidthX, (PlayerBoxSizeY + BoxSpaceY) * i + BoxTextOffsetY);
			Canvas.DrawText(KFPRI.Kills, true);
		
       		Canvas.DrawColor = default.DarkGrayColor;
			Canvas.StrLen(KFPRI.KillAssists, AssistsWidthX, YL);
			Canvas.SetPos(AssistsXPos - 0.5 * AssistsWidthX, (PlayerBoxSizeY + BoxSpaceY) * i + BoxTextOffsetY);
			Canvas.DrawText(KillAssistsSeparator $ KFPRI.KillAssists, true);
		}

        // Draw husk Kill
        Canvas.DrawColor = default.OrangeRedColor;
        Canvas.StrLen(SBKFPRI.HuskKilled, HuskWidthX, YL);
        Canvas.SetPos(HuskXPos - 0.5 * HuskWidthX, (PlayerBoxSizeY + BoxSpaceY) * i + BoxTextOffsetY);
        Canvas.DrawText(SBKFPRI.HuskKilled, true);

		// Draw SC Kill
        Canvas.DrawColor = default.OrangeColor;
		Canvas.StrLen(SBKFPRI.SCKilled, SCWidthx, YL);
        Canvas.SetPos(SCXPos - 0.5 * SCWidthx, (PlayerBoxSizeY + BoxSpaceY) * i + BoxTextOffsetY);
        Canvas.DrawText(SBKFPRI.SCKilled, true);

        // Draw fp Kill
       	Canvas.DrawColor = HUDClass.default.RedColor;
        Canvas.StrLen(SBKFPRI.FPKilled, FPWidthX, YL);
        Canvas.SetPos(FPXPos - 0.5 * FPWidthX, (PlayerBoxSizeY + BoxSpaceY) * i + BoxTextOffsetY);
        Canvas.DrawText(SBKFPRI.FPKilled, true);

       	Canvas.DrawColor = HUDClass.default.WhiteColor;
		
		// draw cash
		CashString = "£"@string(int(TeamPRIArray[i].Score)) ;

		if(TeamPRIArray[i].Score >= 1000)
		{
			CashString = "£"@string(TeamPRIArray[i].Score/1000.f)$"K" ;
		}

		Canvas.StrLen(CashString,CashX,YL);
		Canvas.SetPos(ScoreXPos - CashX/2 , (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY);
		Canvas.DrawColor = Canvas.MakeColor(255,255,125,255);
		Canvas.DrawText(CashString);
		Canvas.DrawColor = default.YellowColor;
		
		// Draw time
		if( GRI.ElapsedTime<KFPlayerReplicationInfo(GRI.PRIArray[i]).StartTime ) // Login timer error, fix it.
			GRI.ElapsedTime = KFPlayerReplicationInfo(GRI.PRIArray[i]).StartTime;
		PlayerTime = FormatTime(GRI.ElapsedTime - KFPlayerReplicationInfo(GRI.PRIArray[i]).StartTime);
		Canvas.StrLen(PlayerTime, TimeWidthX, YL);
		Canvas.SetPos(TimeXPos - 0.5 * TimeWidthX, (PlayerBoxSizeY + BoxSpaceY) * i + BoxTextOffsetY);
		Canvas.DrawText(PlayerTime, true);
	    Canvas.DrawColor = default.DodgerBlueColor;

		// Draw health status

		HealthString = KFPRI.PlayerHealth$" HP" ;
		Canvas.StrLen(HealthString,HealthWidthX,YL);
		Canvas.SetPos(HealthXpos - HealthWidthX/2, (PlayerBoxSizeY + BoxSpaceY) * i + BoxTextOffsetY);

		if ( TeamPRIArray[i].bOutOfLives )
		{
			Canvas.StrLen(OutText,OutX,YL);
			Canvas.DrawColor = HUDClass.default.RedColor;
			Canvas.SetPos(HealthXpos - OutX/2, (PlayerBoxSizeY + BoxSpaceY) * i + BoxTextOffsetY);
			Canvas.DrawText(OutText);
		}
		else
		{
			if( KFPRI.PlayerHealth>=80 )
			{
				Canvas.DrawColor = default.WhiteColor;
			}
			else if( KFPRI.PlayerHealth>=50 )
			{
				Canvas.DrawColor = default.GrayColor;
			}
			else
			{
				Canvas.DrawColor = default.DarkGrayColor;
			}
			Canvas.DrawText(HealthString);
		}
	}

	if (Level.NetMode == NM_Standalone)
		return;

	Canvas.StrLen(NetText, NetXL, YL);
	Canvas.DrawColor = default.WhiteColor;
	Canvas.SetPos(NetXPos - 0.5 * NetXL, TitleYPos);
	Canvas.DrawText(NetText,true);

	for (i=0; i<GRI.PRIArray.Length; i++)
		PRIArray[i] = GRI.PRIArray[i];

	DrawNetInfo(Canvas, FontReduction, HeaderOffsetY, PlayerBoxSizeY, BoxSpaceY, BoxTextOffsetY, OwnerOffset, PlayerCount, NetXPos);
	DrawMatchID(Canvas, FontReduction);
}



/* Returns a color value for the supplied ping */
function Color GetPingNewColor( int Ping)
{
    if(Ping >= 200)
    {
		return default.DarkGrayColor;
    }
    else if( Ping >= 100)
    {
		return default.GrayColor;
    }
    else if( Ping < 100)
    {
		return default.WhiteColor;
    }
}


static final function string ParseTags(string S)
{
    local int i;
    local string NewTag, newCode;

    CheckColorCodes();
    
    for(i=0;i < default.ColorList.Length;i++)
    {
        NewTag = default.ColorList[i].Tag;
        newCode = default.colorCodes[i];
        ReplaceText(S, NewTag, newCode);
    }
    return S;
}


static final function CheckColorCodes()
{
    if(!default.bMadeColorCodes)
    {
        MakeColorCodes();
    }
}


static final function MakeColorCodes()
{
    local int i;

    for(i=0;i < default.ColorList.Length;i++)
    {
        default.colorCodes[default.colorCodes.Length] = GetColorCode(default.ColorList[i].RGB);
    }
    default.bMadeColorCodes = true;
}


static final function string GetColorCode(string rgbString)
{
    local Color NewColor;
    local array<string> RGB;

    Split(rgbString, ",", RGB);
    NewColor.R = byte(Clamp(int(RGB[0]), 1, 255));
    NewColor.G = byte(Clamp(int(RGB[1]), 1, 255));
    NewColor.B = byte(Clamp(int(RGB[2]), 1, 255));
    return ((Chr(27) $ Chr(NewColor.R)) $ Chr(NewColor.G)) $ Chr(NewColor.B);
}



defaultproperties
{
     FPText="FleshPound"
     SCText="Scrake"
     HuskText="Husk"
	 KillsText="Kill"
     KillAssistsSeparator=" +"
     AssistsHeaderText="Assist"
	 PlayerText="Player"
	 PointsText="Dosh"
	 TimeText="Time"
	 NetText="Ping"
	 HealthText="Health"
     NotShownInfo="player names not shown"
     PlayerCountText="Player:"
     SpectatorCountText="| Spec:"
     AliveCountText="| Alive:"
     BotText="Bot"
     WhiteColor=(B=255,G=255,R=255,A=255)
     GrayColor=(B=192,G=192,R=192,A=255)
     DarkGrayColor=(B=128,G=128,R=128,A=255)
     DodgerBlueColor=(B=255,G=144,R=30,A=255)
     YellowColor=(G=255,R=255,A=255)
     OrangeRedColor=(R=235,G=222,B=30,A=255)
	 OrangeColor=(R=223,G=89,B=17,A=255)
     ColorList(0)=(Color="Red",Tag="%r",RGB="255,1,1")
     ColorList(1)=(Color="Blue",Tag="%b",RGB="0,100,200")
     ColorList(2)=(Color="Cyan",Tag="%c",RGB="0,255,255")
     ColorList(3)=(Color="Green",Tag="%g",RGB="0,255,0")
     ColorList(4)=(Color="Orange",Tag="%o",RGB="200,77,0")
     ColorList(5)=(Color="Purple",Tag="%p",RGB="128,0,128")
     ColorList(6)=(Color="Violet",Tag="%v",RGB="255,0,139")
     ColorList(7)=(Color="White",Tag="%w",RGB="255,255,255")
     ColorList(8)=(Color="Yellow",Tag="%y",RGB="255,255,0")
}
