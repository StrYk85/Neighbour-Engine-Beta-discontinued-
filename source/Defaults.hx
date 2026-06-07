package;

import flixel.util.FlxColor;
import openfl.utils.Assets;

class Defaults {
    inline public static var ENGINE_VERSION:String = 'BETA';
    inline public static var ENGINE_TITLE:String = 'Neighbour Engine';
	inline public static var GAME_VERSION:String = '0.2.7.1';

    inline public static var OPPONENT_COLOR:FlxColor = 0xFFFF0000;
    inline public static var PLAYER_COLOR:FlxColor = 0xFF66FF33;

    inline public static var MISS_COLOR = 0xFF565694;

    public static var NOTE_DIRECTIONS:Array<String> = ['Left', 'Down', 'Up', 'Right'];
    public static var NOTE_COLOR_NAMES:Array<String> = ['Purple', 'Blue', 'Green', 'Red'];
    public static var NOTE_COLORS:Array<FlxColor> = [0xFFC24B99, 0xFF00FFFF, 0xFF12FA05, 0xFFF9393F];

    inline public static var SOUND_EXT = #if web 'mp3' #else 'ogg' #end;

    public static function checkStage(song:String, weekNum:Int):String {
        var daStage:String = 'stage'; 

        var songLowercase = StringTools.replace(song, ' ', '-').toLowerCase();
        switch(weekNum) {
			case 2: 
				daStage = 'halloween';
			case 3: 
				daStage = 'philly';
			case 4: 
				daStage = 'limo';
			case 5: 
				if (songLowercase == 'winter-horrorland') 
					daStage = 'mallEvil'; 
				else 
					daStage = 'mall';
			case 6: 
				if (songLowercase == 'thorns') 
					daStage = 'schoolEvil'; 
				else 
					daStage = 'school';
		}

        return daStage;
    }

    public static function checkGirlfriend(weekNum:Int):String {
        var daGF:String = 'gf';

        switch(weekNum) {
			case 4: daGF = 'gf-car';
			case 5: daGF = 'gf-christmas';
			case 6: daGF = 'gf-pixel';
		}

        return daGF;
    }
}