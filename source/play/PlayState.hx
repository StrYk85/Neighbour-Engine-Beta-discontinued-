package play;
import play.notes.Strumline;
import play.notes.Note;
import play.stage.*;
import play.stage.Stage.ObjectData;
import play.ui.*;
import play.pause.*;

import play.Section.SwagSection;
import play.Song.SwagSong;
import graphics.FunkinSprite;
import backend.Defaults;
import backend.Highscore;
import backend.Ratings;

import flixel.FlxCamera;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import haxe.ds.StringMap;
import lime.utils.Assets;

#if windows
import Sys;
import sys.FileSystem;
#end

using StringTools;

class PlayState extends ui.MusicBeatState {
	public static var instance:PlayState = null;

	public static var SONG:SwagSong;
	public static var isStoryMode:Bool = false;
	public static var inChartingState:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var curDifficulty:Int = 1;

	private var vocals:FlxSound;
	public var healthBar:HealthBar;

	public var stageObjects:FlxTypedGroup<FunkinSprite>;

	public var bfStrums:Strumline;
	public var dadStrums:Strumline;

	public var dad:Character;
	public var gf:Character;
	public var boyfriend:Character;

	private var camFollow:FlxObject;

	public var camZooming:Bool = true;
	public var curSong:String = '';
	public var songSpeed:Float = 1;

	public var gfSpeed:Int = 1;
	private var health:Float = 1;
	private var combo:Int = 0;

	public var ratingMap:StringMap<Int> = new StringMap();
	private var ratingGroup:RatingPopup;

	public static var campaignMisses:Int = 0;

	public var accuracy:Float = 0;
	private var totalNotesHit:Int = 0;
	
	private var generatedMusic:Bool = false;
	private var startingSong:Bool = false;

	public var camHUD:FlxCamera;
	private var camGame:FlxCamera;
	public var camOther:FlxCamera;

	public var songScore:Int = 0;
	public static var campaignScore:Int = 0;

	var defaultCamZoom:Float = 1.05;
	var inCutscene:Bool = false;
	
	public static var songOffset:Float = 0; // Per song additive offset
	public static var opponentMode:Bool = false;

	private var paused:Bool = false;
	var canPause:Bool = true;

	public var bf(get, never):Character;
	public function get_bf():Character {
		return boyfriend;
	}

	public var player(get, never):Character;
	public function get_player():Character {
		return opponentMode? dad : boyfriend;
	}

	public var opponent(get, never):Character;
	public function get_opponent():Character {
		return opponentMode? boyfriend : dad;
	}

	public var playerStrums(get, never):Strumline;
	public function get_playerStrums():Strumline {
		return opponentMode? dadStrums : bfStrums;
	}

	public var opponentStrums(get, never):Strumline;
	public function get_opponentStrums():Strumline {
		return opponentMode? bfStrums : dadStrums;
	}

	function setCameras() {
		FlxG.cameras.reset(camGame);
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);
		camOther = new FlxCamera();
		camOther.bgColor.alpha = 0;
		FlxG.cameras.add(camOther, false);
	}

	function setHUD() {
		healthBar = new HealthBar(this, 'health', 0, 2, {
			iconP1: player?.charIcon,
			iconP1Color: player?.iconColor,
			iconP2: opponent?.charIcon,
			iconP2Color: opponent?.iconColor
		}, opponentMode);
		healthBar.screenCenter(X);
		healthBar.y = PlayStateChangeables.useDownscroll? 50 : FlxG.height * 0.9;
		healthBar.cameras = [camHUD];
		add(healthBar);

		var pixelShitPart1:String = 'default/popup/';
		var pixelShitPart2:String = '';

		ratingGroup = new RatingPopup(pixelShitPart1, pixelShitPart2);
		ratingGroup.screenCenter();
		ratingGroup.cameras = [camHUD];
		add(ratingGroup);
	}

	override public function create() {
		instance = this;
		if (FlxG.sound.music != null) FlxG.sound.music.stop();
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		FlxG.fixedTimestep = false;
		PlayStateChangeables.reset();

		for (i in ['sick', 'good', 'bad', 'shit', 'miss']) ratingMap.set(i, 0);
		combo = 0;

		persistentUpdate = persistentDraw = true;

		if (SONG == null) SONG = Song.loadFromJson('tutorial', 'tutorial');
		if (SONG.song == null) trace('song is null???');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		setCameras();
		generateStage();
		camFollow = new FlxObject(0, 0, 2, 2);
		add(camFollow);
		if (dad != null) camFollow.setPosition(dad.getGraphicMidpoint().x + dad.cameraOffsets[0], dad.getGraphicMidpoint().y + dad.cameraOffsets[1]);

		FlxG.camera.follow(camFollow, LOCKON, 0.04);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow.getPosition());
		setHUD();

		generateSong(SONG.song);
		startingSong = true;
		trace('starting');

		startCountdown();

		super.create();

		leftWatermark.cameras = [camHUD];
		leftWatermark.text = '${SONG.song} (${Defaults.difficultyArray[curDifficulty]}) - ${Defaults.ENGINE_TITLE} ${Defaults.ENGINE_VERSION}'; 
	}

	private function generateStage():Void {
		stageObjects = new FlxTypedGroup();
		add(stageObjects);

		var stageCheck:String = SONG.stage;
		if (!Assets.exists(Paths.json('stages/' + stageCheck))) stageCheck = 'default';

		var rawJson = Assets.getText(Paths.json('stages/' + stageCheck));
		var daJson = Json.parse(rawJson);
		var objects:Array<ObjectData> = daJson.objects;

		for (obj in objects) {
			var assetPath = 'stages/$stageCheck/'+ obj.assetPath;
			if (!Assets.exists(Paths.image(assetPath))) assetPath = obj.assetPath;
			var pos = [obj.position[0] ?? 0, obj.position[1] ?? 0];
			var scrollFactor = [];
			if (obj.scrollFactor == null) scrollFactor = [1.0, 1.0];
			else {
				scrollFactor.push(obj.scrollFactor[0] ?? 1.0);
				scrollFactor.push(obj.scrollFactor[1] ?? scrollFactor[0]);
			}
			var scale = obj.scale ?? 1;

			var piss:FunkinSprite = new FunkinSprite(pos[0], pos[1]);
			if (obj.animations == null) {
				piss.loadGraphic(Paths.image(assetPath));
				piss.active = false;
			}
			else {
				for (anim in obj.animations) {
					piss.frames = Paths.getSparrowAtlas(assetPath);
					if (anim.indices == null) piss.animation.addByPrefix(anim.name, anim.prefix, anim.framerate ?? 24, anim.loop ?? false);
					else piss.animation.addByIndices(anim.name, anim.prefix, anim.indices, '', anim.framerate ?? 24, anim.loop ?? false);
					piss.animation.play(anim.name);
				}
			}
			if (scale != 1) {
				piss.setGraphicSize(Std.int(piss.width * scale));
				piss.updateHitbox();
			}
			piss.antialiasing = obj.antialiasing ?? true;
			piss.angle = obj.angle ?? 0;
			piss.alpha = obj.alpha ?? 1;
			piss.color = obj.color ?? -1;
			piss.scrollFactor.set(scrollFactor[0], scrollFactor[1]);

			stageObjects.add(piss);
		}

		defaultCamZoom = Std.parseFloat(daJson.zoom) ?? 1;
		var gfCheck:String = SONG.gfVersion == null? 'gf' : SONG.gfVersion;
		
		gf = new Character(0, 0, gfCheck, false);
		applyCharacterData(gf, 'gf', daJson);
		add(gf);

		boyfriend = new Character(0, 0, SONG.player1, !opponentMode);
		applyCharacterData(boyfriend, 'bf', daJson);
		add(boyfriend);

		dad = new Character(0, 0, SONG.player2, opponentMode);
		applyCharacterData(dad, 'dad', daJson);
		add(dad);
	}

	private function applyCharacterData(char:Character, type:String, json):Void {
		var charData = json.bf;
		switch (type) {
			case 'gf': charData = json.gf;
			case 'dad': charData = json.dad;
			default: charData = json.bf;
		}

		trace('loaded character data for ' + type);

		var scrollFactor = [1.0, 1.0];
		if (charData.scrollFactor != null) {
			scrollFactor[0] = charData.scrollFactor[0] ?? 1.0;
			scrollFactor[1] = charData.scrollFactor[1] ?? scrollFactor[0];
		}

		char.setPosition((charData.position[0] ?? 0) + char.stageOffsets[0], (charData.position[1] ?? 0) + char.stageOffsets[1]);
		char.scrollFactor.set(scrollFactor[0], scrollFactor[1]);
	}

	private function generateSong(dataPath:String):Void {
		generatedMusic = true;
		curSong = dataPath;
		FlxG.sound.cache(Paths.inst(curSong));
		Conductor.changeBPM(SONG.bpm);

		if (SONG.needsVoices) {
			vocals = new FlxSound().loadEmbedded(Paths.voices(curSong));
			FlxG.sound.list.add(vocals);
			trace('loaded vocals');
		}
		songSpeed = FlxMath.roundDecimal(PlayStateChangeables.scrollSpeed == 1? (SONG.speed ?? 1) : PlayStateChangeables.scrollSpeed, 2);
		
		// Per song offset check
		#if windows
			var songLowercase = StringTools.replace(curSong, ' ', '-').toLowerCase();
			var songPath = 'assets/data/songs/' + songLowercase + '/';
			
			for(file in sys.FileSystem.readDirectory(songPath)) {
				var path = haxe.io.Path.join([songPath, file]);

				if(!sys.FileSystem.isDirectory(path)) {
					if(path.endsWith('.offset')) {
						trace('Found offset file: ' + path);
						songOffset = Std.parseFloat(file.substring(0, file.indexOf('.off')));
						break;
					}
					else {
						trace('Offset file not found. Creating one @: ' + songPath);
						sys.io.File.saveContent(songPath + songOffset + '.offset', '');
					}
				}
			}
		#end

		var strumLinePos = PlayStateChangeables.useDownscroll? FlxG.height - 165 : 50;

		dadStrums = new Strumline(!opponentMode, SONG.noteStyle);
		dadStrums.cameras = [camHUD];
		dadStrums.setPosition(100, strumLinePos);
		add(dadStrums);

		bfStrums = new Strumline(PlayStateChangeables.botPlay? true : opponentMode, SONG.noteStyle);
		bfStrums.cameras = [camHUD];
		bfStrums.setPosition(FlxG.width - (Strumline.swagWidth * 4) - 100, strumLinePos);
		add(bfStrums);

		opponentStrums.onNoteHit.add((note:Note) -> botHit(note));
		playerStrums.onNoteHit.add((note:Note) -> playerHit(note));
		playerStrums.onNoteMiss.add((note:Note) -> noteMiss(note));

		trace('now into generating the note data');

		var bfNotes:Array<Dynamic> = [];
		var dadNotes:Array<Dynamic> = [];
		
		for (section in SONG.notes) {
			for (noteParams in section.sectionNotes) {
				var mustHit:Bool = section.mustHitSection;
                if (noteParams[1] > (Strumline.arrowAmount - 1)) mustHit = !section.mustHitSection;
                if (mustHit == opponentMode) dadNotes.push(noteParams);
				else bfNotes.push(noteParams);
			}
		}

		opponentStrums.generateNotes(dadNotes);
		playerStrums.generateNotes(bfNotes);

		for (i => strum in [opponentStrums, playerStrums]) {
			strum.fadeInArrows();
			strum.setSpeed(songSpeed);
		}

		trace('done generating note data');
	}

	var startTimer:FlxTimer;
	function startCountdown():Void {
		inCutscene = false;
		Conductor.songPosition = -Conductor.crochet * 5;

		var swagCounter:Int = 0;
		var introAlts:Array<String> = ['ready', 'set', 'go'];
		var swagCounterSounds:Array<String> = ['3', '2', '1', 'Go'];
		var altPrefix:String = 'notestyles/default/countdown/';
		var altSuffix:String = playerStrums.noteStyle == 'pixel'? '-pixel' : '';

		var countdownSprite:FunkinSprite = new FunkinSprite();
		countdownSprite.cameras = [camHUD];
		countdownSprite.alpha = 0;
		add(countdownSprite);

		startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer) {
			if (swagCounter >= 0 && swagCounter < 4 && countdownSprite != null) {
				FlxG.sound.play(Paths.sound('intro${swagCounterSounds[swagCounter]}' + altSuffix), 0.6);
				if (swagCounter > 0) {
					FlxTween.cancelTweensOf(countdownSprite);
					countdownSprite.alpha = 1;

					countdownSprite.loadGraphic(Paths.image(altPrefix + introAlts[swagCounter - 1]));
					countdownSprite.scrollFactor.set();
					countdownSprite.updateHitbox();
					countdownSprite.screenCenter();

					FlxTween.tween(countdownSprite, {alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween) if (swagCounter > 3) countdownSprite.destroy()
					});
				}
			}

			for (i in [gf, opponent, player]) {
				if (i == null) continue;
				i.dance();
			}
			swagCounter++;
		}, 5);
	}

	var songStarted = false;
	function startSong():Void {
		startingSong = false;
		songStarted = true;

		if (!paused) FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		FlxG.sound.music.onComplete = endSong;
		Conductor.songPosition = 0;
		resyncVocals();
	}

	override function openSubState(SubState:FlxSubState) {
		if (paused) {
			persistentUpdate = false;
			persistentDraw = true;

			if (FlxG.sound.music != null) FlxG.sound.music.pause();
			if (vocals != null) vocals.pause();
			if (!startTimer.finished) startTimer.active = false;
		}
		super.openSubState(SubState);
	}

	override function closeSubState() {
		if (paused) {
			paused = false;
			persistentUpdate = true;
			persistentDraw = true;

			if (FlxG.sound.music != null && !startingSong) resyncVocals();
			if (!startTimer.finished) startTimer.active = true;
		}
		super.closeSubState();
	}

	function resyncVocals():Void {
		if (vocals != null) vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		if (vocals != null) {
			vocals.time = Conductor.songPosition;
			vocals.play();
		}
	}

	private function updateDebugUtils() {
		FlxG.watch.addQuick('beatShit', curBeat);
		FlxG.watch.addQuick('stepShit', curStep);

		if (playerStrums.bot && FlxG.keys.justPressed.ONE) camHUD.visible = !camHUD.visible;
		if (FlxG.keys.justPressed.SEVEN) FlxG.switchState(new debug.ChartingState());
		#if debug
		if (FlxG.keys.justPressed.ONE) endSong();
		#end
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
		healthBar.txt.text = !playerStrums.bot? Ratings.calculateRanking(songScore, ratingMap.get('miss'), accuracy) : 'BOTPLAY';

		if (controls.PAUSE && canPause) {
			if (FlxG.random.bool(0.1)) {
				persistentUpdate = false;
				persistentDraw = true;
				paused = true;
				trace('GITAROO MAN EASTER EGG');
				FlxG.switchState(new GitarooPause());
			}
			else
				goToPauseMenu();
		}

		Conductor.updateSongPosition();
		if (startingSong && Conductor.songPosition >= 0) startSong();

		if (camZooming) {
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
		}

		if (health <= 0 || (FlxG.save.data.resetButton && FlxG.keys.justPressed.R)) die();
		if (!inCutscene) keyShit();

		if (generatedMusic) {
			opponentStrums.updateNotes();
			playerStrums.updateNotes();

			if (PlayState.SONG.notes[Std.int(curStep / 16)] != null) {
				var curTarget = PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection? boyfriend : dad;
				if (curTarget != null) camFollow.setPosition(curTarget.getMidpoint().x + curTarget.cameraOffsets[0], curTarget.getMidpoint().y + curTarget.cameraOffsets[1]);
			}
		}

		updateDebugUtils();
	}

	function die() {
		persistentUpdate = persistentDraw = false;
		paused = true;
		
		if (vocals != null) vocals.stop();
		if (FlxG.sound.music != null) FlxG.sound.music.stop();
		
		openSubState(new GameOverSubstate(player.getScreenPosition()?.x ?? 0, player.getScreenPosition().y ?? 0));
	}

	function endSong():Void {
		if (isStoryMode) campaignMisses = ratingMap.get('miss');
		else {
			PlayStateChangeables.botPlay = false;
			PlayStateChangeables.scrollSpeed = 1;
			PlayStateChangeables.useDownscroll = false;
		}

		canPause = false;
		if (vocals != null) {
			vocals.volume = 0;
			vocals.stop();
		}

		if (FlxG.sound.music != null) {
			FlxG.sound.music.volume = 0;
			FlxG.sound.music.stop();
		}

		var songHighscore = StringTools.replace(PlayState.SONG.song, ' ', '-');
		Highscore.saveScore(songHighscore, Math.round(songScore), curDifficulty);

		if (isStoryMode) {
			campaignScore += Math.round(songScore);
			storyPlaylist.shift();
			
			if (storyPlaylist.length <= 0) {
				transIn = FlxTransitionableState.defaultTransIn;
				transOut = FlxTransitionableState.defaultTransOut;

				FlxG.sound.music.stop();
				//FlxG.sound.playMusic(Paths.music('freakyMenu'));
				FlxG.switchState(new states.MainMenuState());

				//StoryMenuState.weekUnlocked[Std.int(Math.min(storyWeek + 1, StoryMenuState.weekUnlocked.length - 1))] = true;

				Highscore.saveWeekScore(storyWeek, campaignScore, curDifficulty);

				//FlxG.save.data.weekUnlocked = StoryMenuState.weekUnlocked;
				//FlxG.save.flush();
			}
			else {
				var songFormat = StringTools.replace(PlayState.storyPlaylist[0], ' ', '-'); // adjusting the song name to be compatible
				var poop:String = Highscore.formatSong(songFormat, curDifficulty);

				trace('LOADING NEXT SONG');
				trace(poop);

				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;

				PlayState.SONG = Song.loadFromJson(poop, PlayState.storyPlaylist[0]);
				FlxG.sound.music.stop();

				states.LoadingState.loadAndSwitchState(new PlayState());
			}
		}
		else {
			trace('WENT BACK TO FREEPLAY??');
			paused = true;

			if (vocals != null) 
				vocals.stop();
		
			if (FlxG.sound.music != null) 
				FlxG.sound.music.stop();

			FlxG.switchState(new states.FreeplayState());
		}
	}

	private function popUpScore(daNote:Note, noteDiff:Float):Void {
		var score:Float = 350;
		var daRating = daNote.rating;

		switch (daRating) {
			case 'shit':
				score = -300;
				health -= 0.05;
			case 'bad':
				score = 0;
				health -= 0.02;
			case 'good':
				score = 200;
				health += 0.02;
			case 'sick':
				health += 0.05;
		}

		ratingMap.set(daRating, ratingMap.get(daRating) + 1);
		if (daRating == 'shit' || daRating == 'bad') combo = 0;
		if (daRating != 'shit' || daRating != 'bad') songScore += Math.round(score);
		ratingGroup.displayFull(daRating, combo);
	}

	private function keyShit():Void {
		if (playerStrums.bot) return;
		var holdArray:Array<Bool> = [controls.LEFT, controls.DOWN, controls.UP, controls.RIGHT];
		var pressArray:Array<Bool> = [controls.LEFT_P, controls.DOWN_P, controls.UP_P, controls.RIGHT_P];
		var releaseArray:Array<Bool> = [controls.LEFT_R, controls.DOWN_R, controls.UP_R, controls.RIGHT_R];

		for (i => p in pressArray) {
			if (p && generatedMusic) {
				if (playerStrums.strumNotes.members[i].animation.curAnim.name != 'confirm') playerStrums.playPress(i);

				var possibleNotes:Array<Note> = []; // notes that can be hit
				var directionList:Array<Int> = []; // directions that can be hit
				var dumbNotes:Array<Note> = []; // notes to kill later
				var directionsAccounted:Array<Bool> = [false, false, false, false]; // we don't want to do judgments for more than one presses

				playerStrums.notes.forEachAlive(function(daNote:Note) {
					if (daNote.canBeHit && !daNote.tooLate && !daNote.wasGoodHit && !directionsAccounted[daNote.noteData]) {
						if (directionList.contains(daNote.noteData)) {
							directionsAccounted[daNote.noteData] = true;

							for (coolNote in possibleNotes) {
								if (coolNote.noteData == daNote.noteData) {
									if (Math.abs(daNote.strumTime - coolNote.strumTime) < 10) {
										// if it's the same note twice at < 10ms distance, just delete it later
										dumbNotes.push(daNote);
										break;
									}
									else if (daNote.strumTime < coolNote.strumTime) {
										// if daNote is earlier than existing note (coolNote), replace
										possibleNotes.remove(coolNote);
										possibleNotes.push(daNote);
										break;
									}
								}
							}
						}
						else {
							possibleNotes.push(daNote);
							directionList.push(daNote.noteData);
						}
					}
				});

				for (dumbNote in dumbNotes) {
					FlxG.log.add('killing dumb ass note at ' + dumbNote.strumTime);
					playerStrums.byeNote(dumbNote, true);
				}

				possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));
				
				if (possibleNotes.length > 0) {
					for (coolNote in possibleNotes) {
						if (i == (coolNote.noteData % pressArray.length)) {
							playerStrums.hitNote(coolNote);
						}
					}
				}
				else if (!FlxG.save.data.ghost)
					noteMiss(null, i);
			}
		}
			
		for (i => h in holdArray) {
			if (h && generatedMusic) {
				playerStrums.notes.forEach(function(daNote:Note) {
					if (daNote.isSustainNote 
						&& (daNote.canBeHit && !daNote.wasGoodHit)
						&& (daNote.prevNote.sustainParent || daNote.prevNote.wasGoodHit)
						&& i == (daNote.noteData % holdArray.length)) 
						playerStrums.hitNote(daNote);
				});
			}
		}

		for (i => r in releaseArray) if (r) playerStrums.playStatic(i);
		
		if (player != null && player.isSinging() && player.holdTimer > (Conductor.stepCrochet / 1000) * player.singTime && (!holdArray.contains(true) || playerStrums.bot)) {
			player.dance();
		}
	}

	function botHit(note:Note):Void {
		opponent?.sing(Std.int(note.noteData % 4));
		if (vocals != null) vocals.volume = 1;
	}

	function playerHit(note:Note):Void {
        player?.sing(Std.int(note.noteData % 4));

		if (combo % 50 == 0 && combo != 0 && gf != null) gf.taunt();
		if (vocals != null) vocals.volume = 1;
		if (health >= 2) health = 2;

		if (playerStrums.bot) return;

		var noteDiff:Float = -(note.strumTime - Conductor.songPosition);
		note.rating = Ratings.calculateRating(noteDiff);

		totalNotesHit++;
		if (!note.isSustainNote) {
			combo++;
			popUpScore(note, noteDiff);
		}

		updateAccuracy();
	}

	function noteMiss(note:Note, ?direction:Int = 0):Void {
		health -= 0.075;
		songScore -= 10;
		combo = 0;

		ratingMap.set('miss', ratingMap.get('miss') + 1);
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));

		var dir = note != null? Std.int(note.noteData % 4) : (direction ?? 0);
		player?.sing(dir, true);
		if (combo > 75 && gf != null && gf.animOffsets.exists('sad')) gf.playAnim('sad');
		if (vocals != null) vocals.volume = 0;

		if (note != null && !note.isSustainNote) updateAccuracy();
	}

	function updateAccuracy() {
		accuracy = (ratingMap.get('sick') / (totalNotesHit + ratingMap.get('miss'))) * 100;
	}

	public function goToPauseMenu() {
		if (paused) return;
		paused = true;
		persistentUpdate = false;
		persistentDraw = true;
		if (FlxG.sound.music != null) FlxG.sound.music.pause();
		if (vocals != null) vocals.pause();

		var pauseState:PauseSubState = new PauseSubState();
		pauseState.cameras = [camOther];
		openSubState(pauseState);
	}

	override function beatHit() {
		super.beatHit();
		if (SONG.notes[Math.floor(curStep / 16)] != null) {
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM) {
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				FlxG.log.add('CHANGED BPM!');
			}

			if (opponent != null && opponent.curCharacter != 'gf') opponent.dance();
		}

		if (FlxG.save.data.camzoom && camZooming && curBeat % 4 == 0) {
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		if (gf != null && curBeat % gfSpeed == 0) gf.dance();
		if (player != null && !player.isSinging()) player.dance();
		healthBar.bopIcons();
	}

	override function destroy() {
		instance = null;
		super.destroy();
	}
}
