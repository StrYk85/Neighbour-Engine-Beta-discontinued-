package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
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
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import haxe.ds.StringMap;

#if windows
import Sys;
import sys.FileSystem;
#end

import ui.*;
import notes.*;
import debug.*;
import stage.*;
import stage.StageSetup.ObjectData;

import Section.SwagSection;
import Song.SwagSong;

using StringTools;

class PlayState extends MusicBeatState {
	public static var instance:PlayState = null;

	public static var SONG:SwagSong;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public static var weekSong:Int = 0;
	public static var weekScore:Int = 0;

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
	public var curSong:String = "";
	public var songSpeed:Float = 1;

	public var gfSpeed:Int = 1;
	private var health:Float = 1;
	private var combo:Int = 0;

	public var ratingMap:StringMap<Int> = new StringMap();
	private var ratingGroup:RatingPopup;

	public static var campaignMisses:Int = 0;

	public var accuracy:Float = 0;
	private var totalNotesHit:Float = 0;
	private var totalPlayed:Int = 0;
	
	private var generatedMusic:Bool = false;
	private var startingSong:Bool = false;

	public var camHUD:FlxCamera;
	private var camGame:FlxCamera;

	public var dialogue:Array<String> = ['dad:blah blah blah', 'bf:coolswag'];

	public var songScore:Int = 0;
	public static var campaignScore:Int = 0;

	var defaultCamZoom:Float = 1.05;
	public static var daPixelZoom:Float = 6;
	var inCutscene:Bool = false;
	
	public static var songOffset:Float = 0; // Per song additive offset

	public static var opponentMode:Bool = false;

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

	override public function create() {
		instance = this;
		if (FlxG.sound.music != null) FlxG.sound.music.stop();
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		FlxG.fixedTimestep = false;
		PlayStateChangeables.reset();

		for (i in ['sick', 'good', 'bad', 'shit', 'miss']) ratingMap.set(i, 0);
		combo = 0;

		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);

		persistentUpdate = persistentDraw = true;

		if (SONG == null) SONG = Song.loadFromJson('tutorial', 'tutorial');
		if (SONG.song == null) trace('song is null???');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		generateStage();

		camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.setPosition(dad.getGraphicMidpoint().x + dad.cameraOffsets[0], dad.getGraphicMidpoint().y + dad.cameraOffsets[1]);
		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0.04);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow.getPosition());
		
		healthBar = new HealthBar(this, 'health', 0, 2, {
			iconP1: player.charIcon,
			iconP1Color: player.iconColor,
			iconP2: opponent.charIcon,
			iconP2Color: opponent.iconColor
		}, opponentMode);
		healthBar.screenCenter(X);
		healthBar.y = PlayStateChangeables.useDownscroll? 50 : FlxG.height * 0.9;
		healthBar.cameras = [camHUD];
		add(healthBar);

		var pixelShitPart1:String = '';
		var pixelShitPart2:String = '';

		ratingGroup = new RatingPopup(pixelShitPart1, pixelShitPart2);
		ratingGroup.screenCenter();
		ratingGroup.cameras = [camHUD];
		//ratingGroup.y -= 50;
		//ratingGroup.x = FlxG.width * 0.55 - 175;
		add(ratingGroup);

		generateSong(SONG.song);
		startingSong = true;
		trace('starting');

		startCountdown();

		StageSetup.postCreate();
		SongSetup.postCreate();

		super.create();

		leftWatermark.cameras = [camHUD];
		var curDif = storyDifficulty == 2? 'Hard' : storyDifficulty == 1 ? 'Normal' : 'Easy';
		leftWatermark.text = SONG.song + ' (' + curDif + ') - ' + Defaults.ENGINE_TITLE + ' ' + Defaults.ENGINE_VERSION; 
	}

	private function generateStage():Void {
		stageObjects = new FlxTypedGroup();
		add(stageObjects);

		var stageCheck:String = SONG.stage == null? Defaults.checkStage(PlayState.SONG.song, storyWeek) : SONG.stage;
		if (!Assets.exists(Paths.json('stages/' + stageCheck))) stageCheck = 'default';

		var rawJson = Assets.getText(Paths.json('stages/' + stageCheck));
		var daJson = Json.parse(rawJson);
		var objects:Array<ObjectData> = daJson.objects;

		for (obj in objects) {
			var assetPath = 'stages/$stageCheck/'+ obj.assetPath;
			if (!Assets.exists(Paths.image(assetPath))) assetPath = obj.assetPath;
			//trace(obj);
			var pos = [obj.position[0] ?? 0, obj.position[1] ?? 0];
			var scrollFactor = [];
			if (obj.scrollFactor == null) scrollFactor = [1.0, 1.0];
			else {
				scrollFactor.push(obj.scrollFactor[0] ?? 1.0);
				scrollFactor.push(obj.scrollFactor[1] ?? scrollFactor[0]);
			}
			var scale = obj.scale ?? 1;

			var piss:FunkinSprite = new FunkinSprite(pos[0], pos[1], obj.name);
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

		var gfCheck:String = SONG.gfVersion == null? Defaults.checkGirlfriend(storyWeek) : SONG.gfVersion;
		
		gf = new Character(0, 0, gfCheck, false);
		applyCharacterData(gf, 'gf', daJson);
		add(gf);

		boyfriend = new Character(0, 0, SONG.player1, true);
		applyCharacterData(boyfriend, 'bf', daJson);
		add(boyfriend);

		dad = new Character(0, 0, SONG.player2, false);
		applyCharacterData(dad, 'dad', daJson);
		add(dad);

		if (opponentMode) {
			boyfriend.isPlayer = false;
			dad.isPlayer = true;
		}
	}

	private function applyCharacterData(char:Character, type:String, json):Void {
		var charData = json.bf;
		switch (type) {
			case 'gf': charData = json.gf;
			case 'dad': charData = json.dad;
			default: charData = json.bf;
		}

		trace('loaded character data for ' + type);

		var pos = [charData.position[0] ?? 0, charData.position[1] ?? 0];
		var scrollFactor = [];
		if (charData.scrollFactor == null) scrollFactor = [1.0, 1.0];
		else {
			scrollFactor.push(charData.scrollFactor[0] ?? 1.0);
			scrollFactor.push(charData.scrollFactor[1] ?? scrollFactor[0]);
		}

		char.setPosition(pos[0] + char.stageOffsets[0], pos[1] + char.stageOffsets[1]);
		char.scrollFactor.set(scrollFactor[0], scrollFactor[1]);
	}

	private function generateSong(dataPath:String):Void {
		generatedMusic = true;
		Conductor.changeBPM(SONG.bpm);
		curSong = dataPath;
		FlxG.sound.cache(Paths.inst(curSong));

		if (SONG.needsVoices) {
			vocals = new FlxSound().loadEmbedded(Paths.voices(curSong));
			FlxG.sound.list.add(vocals);
			trace('loaded vocals');
		}

		var noteData:Array<SwagSection> = SONG.notes;
		songSpeed = FlxMath.roundDecimal(PlayStateChangeables.scrollSpeed == 1? SONG.speed : PlayStateChangeables.scrollSpeed, 2);
		
		// Per song offset check
		#if windows
			var songLowercase = StringTools.replace(curSong, " ", "-").toLowerCase();
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
		playerStrums.onNoteMiss.add((note:Note) -> noteMiss(Std.int(note.noteData % 4)));

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

		var yeah = [dadNotes, bfNotes];

		for (i => strum in [opponentStrums, playerStrums]) {
			strum.generateNotes(yeah[i]);
			strum.fadeInArrows();
			strum.setSpeed(songSpeed);
		}

		trace('done generating note data');
	}

	var startTimer:FlxTimer;

	function startCountdown():Void {
		inCutscene = false;

		startedCountdown = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		var swagCounter:Int = 0;
		var introAlts:Array<String> = ['ready', 'set', 'go'];
		var altPrefix:String = 'notestyles/default/popup/';
		var altSuffix:String = playerStrums.noteStyle == 'pixel'? '-pixel' : '';

		var countdownSprite:FlxSprite = new FlxSprite();
		countdownSprite.cameras = [camHUD];
		countdownSprite.alpha = 0;
		add(countdownSprite);

		startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer) {
			switch (swagCounter) {
				case 0:
					FlxG.sound.play(Paths.sound('intro3' + altSuffix), 0.6);
				case 1:
					FlxG.sound.play(Paths.sound('intro2' + altSuffix), 0.6);
				case 2:
					FlxG.sound.play(Paths.sound('intro1' + altSuffix), 0.6);
				case 3:
					FlxG.sound.play(Paths.sound('introGo' + altSuffix), 0.6);
			}

			if (swagCounter > 0 && swagCounter < 4 && countdownSprite != null) {
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

			for (i in [gf, opponent, player]) {
				if (swagCounter == 3) i.taunt();
				else i.dance();
			}

			swagCounter++;
		}, 5);
	}

	var previousFrameTime:Int = 0;
	var songStarted = false;

	function startSong():Void {
		startingSong = false;
		songStarted = true;

		if (!paused) FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		if (vocals != null) vocals.play();
		FlxG.sound.music.onComplete = endSong;

		Conductor.songPosition = 0;
		//resyncVocals();
	}

	override function openSubState(SubState:FlxSubState) {
		if (paused) {
			if (FlxG.sound.music != null) FlxG.sound.music.pause();
			if (vocals != null) vocals.pause();
			if (!startTimer.finished) startTimer.active = false;
		}
		super.openSubState(SubState);
	}

	override function closeSubState() {
		if (paused) {
			if (FlxG.sound.music != null && !startingSong) resyncVocals();
			if (!startTimer.finished) startTimer.active = true;
			paused = false;
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

	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	private var scoreHolder:Int = 0;

	override public function update(elapsed:Float) {
		if (playerStrums.bot && FlxG.keys.justPressed.ONE) camHUD.visible = !camHUD.visible;

		super.update(elapsed);
		healthBar.txt.text = !playerStrums.bot? Ratings.calculateRanking(songScore, ratingMap.get('miss'), accuracy) : 'BOTPLAY';

		if (controls.PAUSE && startedCountdown && canPause) {
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			// 1 / 1000 chance for Gitaroo Man easter egg
			if (FlxG.random.bool(0.1)) {
				trace('GITAROO MAN EASTER EGG');
				FlxG.switchState(new GitarooPause());
			}
			else
				openSubState(new PauseSubState(player.getScreenPosition().x, player.getScreenPosition().y));
		}


		if (FlxG.keys.justPressed.SEVEN) FlxG.switchState(new ChartingState());

		if (startingSong) {
			if (startedCountdown) {
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0) startSong();
			}
		}
		else Conductor.songPosition += FlxG.elapsed * 1000;

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null) {
			var curTarget = PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection? boyfriend : dad;
			camFollow.setPosition(curTarget.getMidpoint().x + curTarget.cameraOffsets[0], curTarget.getMidpoint().y + curTarget.cameraOffsets[1]);
		}

		if (camZooming) {
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		if ((health <= 0) || (FlxG.save.data.resetButton && FlxG.keys.justPressed.R)) die();

		if (!inCutscene) keyShit();

		if (generatedMusic) {
			opponentStrums.updateNotes();
			playerStrums.updateNotes();
		}

		#if debug
		if (FlxG.keys.justPressed.ONE) endSong();
		#end

		StageSetup.update();
		SongSetup.update();
	}

	function die() {
		persistentUpdate = false;
		persistentDraw = false;
		paused = true;
		
		if (vocals != null) 
			vocals.stop();
		if (FlxG.sound.music != null) 
			FlxG.sound.music.stop();
		
		openSubState(new GameOverSubstate(player.getScreenPosition().x, player.getScreenPosition().y));
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

		if (SONG.validScore) {
			var songHighscore = StringTools.replace(PlayState.SONG.song, " ", "-");
			Highscore.saveScore(songHighscore, Math.round(songScore), storyDifficulty);
		}

		if (isStoryMode) {
			campaignScore += Math.round(songScore);
			storyPlaylist.remove(storyPlaylist[0]);
			
			if (storyPlaylist.length <= 0) {
				transIn = FlxTransitionableState.defaultTransIn;
				transOut = FlxTransitionableState.defaultTransOut;

				FlxG.sound.music.stop();
				//FlxG.sound.playMusic(Paths.music('freakyMenu'));
				FlxG.switchState(new MainMenuState());

				//StoryMenuState.weekUnlocked[Std.int(Math.min(storyWeek + 1, StoryMenuState.weekUnlocked.length - 1))] = true;

				if (SONG.validScore)
					Highscore.saveWeekScore(storyWeek, campaignScore, storyDifficulty);

				//FlxG.save.data.weekUnlocked = StoryMenuState.weekUnlocked;
				//FlxG.save.flush();
			}
			else {
				var songFormat = StringTools.replace(PlayState.storyPlaylist[0], " ", "-"); // adjusting the song name to be compatible
				var poop:String = Highscore.formatSong(songFormat, storyDifficulty);

				trace('LOADING NEXT SONG');
				trace(poop);

				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;

				PlayState.SONG = Song.loadFromJson(poop, PlayState.storyPlaylist[0]);
				FlxG.sound.music.stop();

				LoadingState.loadAndSwitchState(new PlayState());
			}
		}
		else {
			trace('WENT BACK TO FREEPLAY??');
			paused = true;

			if (vocals != null) 
				vocals.stop();
		
			if (FlxG.sound.music != null) 
				FlxG.sound.music.stop();

			FlxG.switchState(new FreeplayState());
		}
	}

	var endingSong:Bool = false;

	private function popUpScore(daNote:Note, noteDiff:Float):Void {
		var score:Float = 350;
		var daRating = daNote.rating;
		var msTiming = FlxMath.roundDecimal(noteDiff, 3);	

		switch (daRating) {
			case 'shit':
				score = -300;
				health -= 0.05;
				totalNotesHit -= 1;
			case 'bad':
				score = 0;
				health -= 0.02;
				totalNotesHit += 0.25;
			case 'good':
				score = 200;
				health += 0.02;
				totalNotesHit += 0.75;
			case 'sick':
				health += 0.05;
				totalNotesHit += 1;
			}

			ratingMap.set(daRating, ratingMap.get(daRating) + 1);
			if (daRating == 'shit' || daRating == 'bad') {
				//ratingMap.set('miss', ratingMap.get('miss') + 1);
				combo = 0;
			}

			if (daRating != 'shit' || daRating != 'bad') {
				songScore += Math.round(score);
				ratingGroup.displayRating(daRating);
				ratingGroup.displayMS(combo, msTiming, daRating);
			}
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
					FlxG.log.add("killing dumb ass note at " + dumbNote.strumTime);
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
					noteMiss(i);
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

		for (i => r in releaseArray) 
			if (r) playerStrums.playStatic(i);
		
		if (player.holdTimer > (Conductor.stepCrochet / 1000) * player.singTime && (!holdArray.contains(true) || playerStrums.bot)) {
			if (player.animation.curAnim.name.startsWith('sing') && !player.animation.curAnim.name.endsWith('miss'))
				player.playAnim('idle');
		}
	}

	function botHit(note:Note):Void {
		var dir = Std.int(note.noteData % 4);
		opponent.sing(dir);
		if (vocals != null) vocals.volume = 1;
	}

	function playerHit(note:Note):Void {
		var dir = Std.int(note.noteData % 4);
        player.sing(dir);

		if (combo % 50 == 0 && combo != 0) gf.taunt();
		if (vocals != null) vocals.volume = 1;
		if (health >= 2) health = 2;

		if (playerStrums.bot) return;

		var noteDiff:Float = (note.strumTime - Conductor.songPosition) * -1;
		note.rating = Ratings.calculateRating(noteDiff);

		if (!note.isSustainNote) {
			combo++;
			popUpScore(note, noteDiff);
		}
		else 
			totalNotesHit++;

		//if (note.rating == 'sick' && playerStrums.splashes.members[note.noteData] != null) playerStrums.splashes.members[note.noteData].playAnim();
		updateAccuracy();
	}

	function noteMiss(direction:Int = 0):Void {
		health -= 0.075;
		songScore -= 10;
		combo = 0;

		totalNotesHit--;
		ratingMap.set('miss', ratingMap.get('miss') + 1);

		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));

		player.sing(direction, true);
		if (combo > 75 && gf.animOffsets.exists('sad')) gf.playAnim('sad');
		if (vocals != null) vocals.volume = 0;

		updateAccuracy();
	}

	function updateAccuracy() {
		totalPlayed++;
		accuracy = (totalNotesHit / totalPlayed) * 100;
	}

	public function focusOut() {
		if (paused) return;
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;
		
		if (FlxG.sound.music != null) 
			FlxG.sound.music.pause();
			
		if (vocals != null)
			vocals.pause();
		
		openSubState(new PauseSubState(player.getScreenPosition().x, player.getScreenPosition().y));
	}

	override function stepHit() {
		super.stepHit();
		if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20)
			resyncVocals();

		StageSetup.stepHit(curStep);
		SongSetup.stepHit(curStep);
	}

	override function beatHit() {
		super.beatHit();

		if (SONG.notes[Math.floor(curStep / 16)] != null) {
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM) {
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				FlxG.log.add('CHANGED BPM!');
			}

			// Dad doesnt interupt his own notes
			var canDance:Bool = (SONG.notes[Math.floor(curStep / 16)].mustHitSection && !opponentMode)
			|| (!SONG.notes[Math.floor(curStep / 16)].mustHitSection && opponentMode);

			if (canDance && dad.curCharacter != 'gf')
				opponent.dance();
		}

		if (FlxG.save.data.camzoom) {
			if (camZooming && curBeat % 4 == 0) {
				FlxG.camera.zoom += 0.015;
				camHUD.zoom += 0.03;
			}
		}

		for (icon in [healthBar.iconP1, healthBar.iconP2]) {
			icon.setGraphicSize(Std.int(icon.width + 30));
			icon.updateHitbox();
		}

		if (curBeat % gfSpeed == 0) gf.dance();

		if (!player.animation.curAnim.name.startsWith("sing")) player.dance();
		
		StageSetup.beatHit(curBeat);
		SongSetup.beatHit(curBeat);
	}
}
