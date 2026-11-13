package states;

import flixel.input.gamepad.FlxGamepad;
import graphics.FunkinSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import play.ui.HealthIcon;
import play.PlayState;
import ui.Alphabet;
import backend.Highscore;

using StringTools;

class FreeplayState extends ui.MusicBeatState {
	var songs:Array<SongMetadata> = [];
	var curSelected:Int = 0;
	var curDifficulty:Int = 1;

	var scoreText:FlxText;
	var comboText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;
	var combo:String = '';

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	override function create() {
		var initSonglist = CoolUtil.coolTextFile(Paths.txt('songs/freeplaySonglist'));

		for (i in 0...initSonglist.length) {
			var data:Array<String> = initSonglist[i].split(':');
			songs.push(new SongMetadata(data[0], Std.parseInt(data[2]), data[1]));
		}

		var bg:FunkinSprite = new FunkinSprite();
		bg.loadGraphic(Paths.image('mainmenu/menuBGBlue'));
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length) {
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);
		}

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, '', 32).setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, RIGHT);
		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, '', 24);
		comboText = new FlxText(diffText.x + 100, diffText.y, 0, '', 24);
		comboText.font = diffText.font = scoreText.font;

		var scoreBG:FunkinSprite = new FunkinSprite(scoreText.x - 6, 0);
		scoreBG.makeSolid(Std.int(FlxG.width * 0.35), 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		for (i in [diffText, comboText, scoreText]) {i.antialiasing = true; add(i);}

		changeSelection(0, true);
		changeDiff(0, true);

		super.create();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String) {
		songs.push(new SongMetadata(songName, weekNum, songCharacter));
	}

	public function addWeek(songs:Array<String>, weekNum:Int, ?songCharacters:Array<String>) {
		if (songCharacters == null) songCharacters = ['dad'];

		var num:Int = 0;
		for (song in songs) {
			addSong(song, weekNum, songCharacters[num]);
			if (songCharacters.length != 1) num++;
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (FlxG.sound.music.volume < 0.7) FlxG.sound.music.volume += 0.5 * FlxG.elapsed;

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));
		if (Math.abs(lerpScore - intendedScore) <= 10) lerpScore = intendedScore;

		scoreText.text = 'PERSONAL BEST: ${flixel.util.FlxStringUtil.formatMoney(lerpScore, false)}';
		comboText.text = combo + '\n';

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
		if (gamepad != null) {
			changeSelection(gamepad.justPressed.DPAD_UP? -1 : gamepad.justPressed.DPAD_DOWN? 1 : 0);
			changeDiff(gamepad.justPressed.DPAD_LEFT? -1 : gamepad.justPressed.DPAD_RIGHT? 1 : 0);
		}

		changeSelection(FlxG.keys.justPressed.UP? -1 : FlxG.keys.justPressed.DOWN? 1 : 0);
		changeDiff(FlxG.keys.justPressed.LEFT? -1 : FlxG.keys.justPressed.RIGHT? 1 : 0);

		if (controls.BACK) FlxG.switchState(new MainMenuState());
		if (controls.ACCEPT)
		{
			// adjusting the song name to be compatible
			var songFormat = StringTools.replace(songs[curSelected].songName, ' ', '-');
			trace(songs[curSelected].songName);

			var poop:String = Highscore.formatSong(songFormat, curDifficulty);
			trace(poop);
			
			PlayState.SONG = play.Song.loadFromJson(poop, songs[curSelected].songName);
			PlayState.isStoryMode = false;
			PlayState.curDifficulty = curDifficulty;
			PlayState.storyWeek = songs[curSelected].week;
			LoadingState.loadAndSwitchState(new PlayState());
		}
	}

	function setupScore() {
		#if !switch
		var songHighscore = StringTools.replace(songs[curSelected].songName, ' ', '-');
		intendedScore = Highscore.getScore(songHighscore, curDifficulty);
		combo = Highscore.getCombo(songHighscore, curDifficulty);
		#end
	}

	function changeDiff(change:Int = 0, force:Bool = false) {
		if (change == 0 && !force) return;
		if (!force) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, 2);
		setupScore();

		diffText.text = CoolUtil.difficultyFromInt(curDifficulty).toUpperCase();
	}

	function changeSelection(change:Int = 0, force:Bool = false) {
		if (change == 0 && !force) return;
		if (!force) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		curSelected = FlxMath.wrap(curSelected + change, 0, songs.length - 1);
		setupScore();

		for (i in 0...iconArray.length) iconArray[i].alpha = i == curSelected? 1 : 0.6;
		for (a => item in grpSongs.members) {
			item.targetY = a - curSelected;
			item.alpha = item.targetY == 0? 1 : 0.6;
		}
	}
}

class SongMetadata {
	public var songName:String = '';
	public var week:Int = 0;
	public var songCharacter:String = '';

	public function new(song:String, week:Int, songCharacter:String) {
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
	}
}
