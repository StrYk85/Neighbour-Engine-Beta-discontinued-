package debug;

import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import haxe.Json;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;
import flixel.util.FlxStringUtil;

import play.ui.HealthIcon;
import play.PlayState;
import play.Conductor;
import play.Conductor.BPMChangeEvent;
import play.Section.SwagSection;
import play.Section;
import play.Song.SwagSong;
import play.Song;
import ui.DefaultText;
import graphics.FunkinSprite;

using StringTools;

class ChartingState extends flixel.addons.ui.FlxUIState
{
	/*
		charting menu fixes and changes by @OldFlag (thanks man !! :D)
	 */
	var _file:FileReference;

	var UI_box:FlxUITabMenu;

	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	 */
	var curSection:Int = 0;
	public static var lastSection:Int = 0;

	var infoTxt:DefaultText;

	var strumLine:FunkinSprite;
	var amountSteps:Int = 0;
	var bullshitUI:FlxGroup;

	var highlight:FlxSprite;

	var GRID_SIZE:Int = 40;

	var dummyArrow:FunkinSprite;

	var curRenderedNotes(default, null):FlxTypedGroup<ChartNote> = new FlxTypedGroup<ChartNote>();
	private var recyclableNotes(default, null):FlxTypedGroup<ChartNote> = new FlxTypedGroup<ChartNote>();

	var gridBG:FlxSprite;

	public static var _songID:String = 'tutorial-hard';
	var _song:SwagSong;
	var songName:String;
	var curDifficulty:String = 'Normal';
	private var songDifficulty:String = 'Normal';

	var typingShit:FlxInputText;
	/*
	 * WILL BE THE CURRENT / LAST PLACED NOTE
	**/
	var curSelectedNote:Array<Dynamic>;

	var tempBpm:Float = 0;
	var vocals:FlxSound;

	var leftIcon:HealthIcon;
	var rightIcon:HealthIcon;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	private var curMeasure:Int = 0;

	override function create() {
		curSection = lastSection;

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('mainmenu/menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF2C2C2C;
		add(bg);

		gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 8, GRID_SIZE * 16);
		add(gridBG);

		_song = PlayState.SONG != null? PlayState.SONG : Song.loadFromJson('tutorial-hard', 'tutorial');

		FlxG.mouse.visible = true;
		FlxG.save.bind('funkin', 'ninjamuffin99');

		leftIcon = new HealthIcon(_song.player1);
		rightIcon = new HealthIcon(_song.player2);
		leftIcon.scrollFactor.set(1, 1);
		rightIcon.scrollFactor.set(1, 1);

		leftIcon.setGraphicSize(0, 45);
		rightIcon.setGraphicSize(0, 45);

		add(leftIcon);
		add(rightIcon);

		leftIcon.setPosition(0, -100);
		rightIcon.setPosition(gridBG.width / 2, -100);

		tempBpm = Std.int(_song.bpm);

		addSection();
		updateGrid();

		loadSong(_song.song);
		Conductor.changeBPM(_song.bpm);
		Conductor.mapBPMChanges(_song);
		songName = _song.song;
		curDifficulty = getDifficulty(_songID);
		songDifficulty = curDifficulty;

		infoTxt = new DefaultText(1000, 50, '', true);
		infoTxt.scrollFactor.set();
		add(infoTxt);

		strumLine = new FunkinSprite(0, 50);
		strumLine.makeSolid(Std.int(FlxG.width / 2), 4, -1);
		add(strumLine);

		dummyArrow = new FunkinSprite(0, 0);
		dummyArrow.makeSolid(GRID_SIZE, GRID_SIZE, -1);
		add(dummyArrow);

		var tabs = [
			{name: "Song", label: 'Song'},
			{name: "Section", label: 'Section'},
			{name: "Note", label: 'Note'},
			{name: "Assets", label: 'Assets'}
		];

		UI_box = new FlxUITabMenu(null, tabs, true);

		UI_box.resize(300, 400);
		UI_box.x = FlxG.width / 2;
		UI_box.y = 20;
		add(UI_box);

		addSongUI();
		addSectionUI();
		addNoteUI();
		addAssetsUI();

		add(curRenderedNotes);

		changeSection();
		super.create();
	}

	function addSongUI():Void {
		var UI_songTitle = new FlxUIInputText(10, 10, 70, _song.song, 8);
		typingShit = UI_songTitle;

		var check_voices = new FlxUICheckBox(10, 25, null, null, "Has vocal track", 100);
		check_voices.checked = _song.needsVoices;

		check_voices.callback = function() {
			_song.needsVoices = check_voices.checked;
			trace('CHECKED IF SONG NEEDS VOCALS!');
		};

		var saveButton:FlxButton = new FlxButton(110, 8, "Save", () -> saveLevel());
		var reloadSong:FlxButton = new FlxButton(saveButton.x + saveButton.width + 10, saveButton.y, "Reload Audio", () -> loadSong(_song.song));
		var reloadSongJson:FlxButton = new FlxButton(reloadSong.x, saveButton.y + 30, "Reload JSON", () -> loadJson(_song.song.toLowerCase()));
		var loadAutosaveBtn:FlxButton = new FlxButton(reloadSongJson.x, reloadSongJson.y + 30, 'Load Autosave', loadAutosave);

		var dificulties = backend.Defaults.difficultyArray.copy();
		var difficultyList = InterfaceUtil.createDropDown(loadAutosaveBtn.x - 30, loadAutosaveBtn.y + 40, 'Difficulty', dificulties, 
		function(dif:String) {curDifficulty = dificulties[Std.parseInt(dif)];}, curDifficulty);

		var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(10, 80, 0.1, 1, 0.1, 10, 1);
		stepperSpeed.value = _song.speed;
		stepperSpeed.name = 'song_speed';
		var speedLabel = new FlxText(70, stepperSpeed.y, 64, 'Song speed');

		var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, 65, 1, 1, 1, 339, 0);
		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';
		var bpmLabel = new FlxText(70, stepperBPM.y, 64, 'BPM');

		var instVolume:FlxUINumericStepper = new FlxUINumericStepper(10, 200, 0.1, 1, 0, 1, 1);
		instVolume.value = FlxG.sound.music.volume;
		instVolume.name = 'inst_volume';
		var instLabel = new FlxText(70, instVolume.y, 84, 'Instrumental Volume');

		var tab_group_song = new FlxUI(null, UI_box);
		tab_group_song.name = "Song";
		tab_group_song.add(UI_songTitle);

		tab_group_song.add(check_voices);
		tab_group_song.add(saveButton);
		tab_group_song.add(reloadSong);
		tab_group_song.add(reloadSongJson);
		tab_group_song.add(loadAutosaveBtn);
		tab_group_song.add(stepperBPM);
		tab_group_song.add(stepperSpeed);
		tab_group_song.add(instVolume);

		tab_group_song.add(speedLabel);
		tab_group_song.add(bpmLabel);
		tab_group_song.add(instLabel);
		tab_group_song.add(difficultyList);

		UI_box.addGroup(tab_group_song);
		UI_box.scrollFactor.set();

		FlxG.camera.follow(strumLine);
	}

	function addAssetsUI() {
		var characters:Array<String> = CoolUtil.coolTextFile(Paths.txt('characters/characterList'));
		var gfVersions:Array<String> = CoolUtil.coolTextFile(Paths.txt('characters/gfVersionList'));
		var stages:Array<String> = CoolUtil.coolTextFile(Paths.txt('stages/stageList'));
		var noteStyles:Array<String> = CoolUtil.coolTextFile(Paths.txt('noteStyleList'));

		var player1DropDown = InterfaceUtil.createDropDown(10, 30, 'Player', characters, function(char:String) {
			_song.player1 = characters[Std.parseInt(char)];
			updateHeads();
		}, _song.player1);

		var player2DropDown = InterfaceUtil.createDropDown(140, 30, 'Opponent', characters, function(char:String) {
			_song.player2 = characters[Std.parseInt(char)];
			updateHeads();
		}, _song.player2);

		var gfVersionDropDown = InterfaceUtil.createDropDown(10, 80, 'Partner', gfVersions, function(gf:String) {
			_song.gfVersion = gfVersions[Std.parseInt(gf)];
		}, _song.gfVersion);

		var stageDropDown = InterfaceUtil.createDropDown(140, 80, 'Stage', stages, function(stage:String) {
			_song.stage = stages[Std.parseInt(stage)];
		}, _song.stage);

		var noteStyleDropDown = InterfaceUtil.createDropDown(10, 130, 'NoteSkin', noteStyles, function(style:String) {
			_song.noteStyle = noteStyles[Std.parseInt(style)];
		}, _song.noteStyle);

		var tab_group_assets = new FlxUI(null, UI_box);
		tab_group_assets.name = "Assets";

		tab_group_assets.add(player1DropDown);
		tab_group_assets.add(player2DropDown);
		tab_group_assets.add(gfVersionDropDown);
		tab_group_assets.add(stageDropDown);
		tab_group_assets.add(noteStyleDropDown);

		UI_box.addGroup(tab_group_assets);
	}

	var stepperLength:FlxUINumericStepper;
	var check_mustHitSection:FlxUICheckBox;
	var check_changeBPM:FlxUICheckBox;
	var stepperSectionBPM:FlxUINumericStepper;
	var check_altAnim:FlxUICheckBox;

	function addSectionUI():Void {
		var tab_group_section = new FlxUI(null, UI_box);
		tab_group_section.name = 'Section';

		stepperLength = new FlxUINumericStepper(10, 10, 4, 0, 0, 999, 0);
		stepperLength.value = _song.notes[curSection].lengthInSteps;
		stepperLength.name = "section_length";

		stepperSectionBPM = new FlxUINumericStepper(10, 80, 1, Conductor.bpm, 0, 999, 0);
		stepperSectionBPM.value = Conductor.bpm;
		stepperSectionBPM.name = 'section_bpm';

		var stepperCopy:FlxUINumericStepper = new FlxUINumericStepper(110, 130, 1, 1, -999, 999, 0);
		var stepperCopyLabel = new FlxText(174, 132, 'sections back');

		var copyButton:FlxButton = new FlxButton(10, 130, "Copy last section", function()
		{
			copySection(Std.int(stepperCopy.value));
		});

		var clearSectionButton:FlxButton = new FlxButton(10, 150, "Clear", clearSection);

		var swapSection:FlxButton = new FlxButton(10, 170, "Swap section", function()
		{
			for (i in 0..._song.notes[curSection].sectionNotes.length)
			{
				var note = _song.notes[curSection].sectionNotes[i];
				note[1] = (note[1] + 4) % 8;
				_song.notes[curSection].sectionNotes[i] = note;
				updateGrid();
			}
		});

		check_mustHitSection = new FlxUICheckBox(10, 30, null, null, "Must hit section", 100);
		check_mustHitSection.name = 'check_mustHit';
		check_mustHitSection.checked = true;

		check_altAnim = new FlxUICheckBox(10, 400, null, null, "Alt Animation", 100);
		check_altAnim.name = 'check_altAnim';

		check_changeBPM = new FlxUICheckBox(10, 60, null, null, 'Change BPM', 100);
		check_changeBPM.name = 'check_changeBPM';

		tab_group_section.add(stepperLength);
		tab_group_section.add(stepperSectionBPM);
		tab_group_section.add(stepperCopy);
		tab_group_section.add(stepperCopyLabel);
		tab_group_section.add(check_mustHitSection);
		tab_group_section.add(check_altAnim);
		tab_group_section.add(check_changeBPM);
		tab_group_section.add(copyButton);
		tab_group_section.add(clearSectionButton);
		tab_group_section.add(swapSection);

		UI_box.addGroup(tab_group_section);
	}

	var stepperSusLength:FlxUINumericStepper;

	function addNoteUI():Void
	{
		var tab_group_note = new FlxUI(null, UI_box);
		tab_group_note.name = 'Note';

		stepperSusLength = new FlxUINumericStepper(10, 10, Conductor.stepCrochet / 2, 0, 0, Conductor.stepCrochet * 16);
		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';

		var applyLength:FlxButton = new FlxButton(100, 10, 'Apply');

		tab_group_note.add(stepperSusLength);
		tab_group_note.add(applyLength);

		UI_box.addGroup(tab_group_note);
	}

	function loadSong(daSong:String):Void
	{
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
			// vocals.stop();
		}

		FlxG.sound.playMusic(Paths.inst(daSong), 0.6);

		// WONT WORK FOR TUTORIAL OR TEST SONG!!! REDO LATER
		vocals = new FlxSound().loadEmbedded(Paths.voices(daSong));
		FlxG.sound.list.add(vocals);

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.onComplete = function()
		{
			vocals.pause();
			vocals.time = 0;
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
		};
	}

	function generateUI():Void {
		while (bullshitUI.members.length > 0)
			bullshitUI.remove(bullshitUI.members[0], true);

		// general shit
		var title:FlxText = new FlxText(UI_box.x + 20, UI_box.y + 20, 0);
		bullshitUI.add(title);
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUICheckBox.CLICK_EVENT)
		{
			var check:FlxUICheckBox = cast sender;
			var label = check.getLabel().text;
			switch (label)
			{
				case 'Must hit section':
					_song.notes[curSection].mustHitSection = check.checked;
					updateHeads();
				case 'Change BPM':
					_song.notes[curSection].changeBPM = check.checked;
					FlxG.log.add('changed bpm shit');
				case "Alt Animation":
					_song.notes[curSection].altAnim = check.checked;
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;
			FlxG.log.add(wname);
			if (wname == 'section_length') {
				if (nums.value <= 4) nums.value = 4;
				_song.notes[curSection].lengthInSteps = Std.int(nums.value);
				updateGrid();
			}
			else if (wname == 'song_speed') {
				if (nums.value <= 0) nums.value = 0;
				_song.speed = nums.value;
			}
			else if (wname == 'song_bpm') {
				if (nums.value <= 0) nums.value = 1;
				tempBpm = Std.int(nums.value);
				Conductor.mapBPMChanges(_song);
				Conductor.changeBPM(Std.int(nums.value));
			}
			else if (wname == 'inst_volume') {
				if (nums.value <= 0) nums.value = 0;
				FlxG.sound.music.volume = FlxMath.roundDecimal(nums.value, 1);
			}
			else if (wname == 'note_susLength') {
				if (curSelectedNote == null)
					return;

				if (nums.value <= 0) nums.value = 0;

				curSelectedNote[2] = nums.value;
				updateGrid();
			}
			else if (wname == 'section_bpm') {
				if (nums.value <= 0.1) nums.value = 0.1;
				_song.notes[curSection].bpm = Std.int(nums.value);
				updateGrid();
			}
		}
	}

	function sectionStartTime():Float {
		var daBPM:Float = _song.bpm;
		var daPos:Float = 0;
		for (i in 0...curSection) {
			if (_song.notes[i].changeBPM) daBPM = _song.notes[i].bpm;

			daPos += 4 * (1000 * 60 / daBPM);
		}
		return daPos;
	}

	override function update(elapsed:Float) {
		curStep = updateCurStep(false);

		Conductor.songPosition = FlxG.sound.music.time;
		_song.song = typingShit.text;

		strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) % (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps));

		if (curBeat % 4 == 0 && curStep >= 16 * (curSection + 1)) {
			trace(curStep);
			trace((_song.notes[curSection].lengthInSteps) * (curSection + 1));
			trace('DUMBSHIT');

			if (_song.notes[curSection + 1] == null) addSection();

			changeSection(curSection + 1, false);
		}
		else if (strumLine.y < -10) {
			if (_song.notes[curSection - 1] == null) {
				FlxG.sound.music.time = 0;
				vocals.time = FlxG.sound.music.time;
			}

			changeSection(curSection - 1, false);
		}

		FlxG.watch.addQuick('daBeat', curBeat);
		FlxG.watch.addQuick('daStep', curStep);

		if (FlxG.mouse.justPressed) {
			if (FlxG.mouse.overlaps(curRenderedNotes)) {
				curRenderedNotes.forEach(function(note:ChartNote) {
					if (FlxG.mouse.overlaps(note)) {
						if (FlxG.keys.pressed.CONTROL)
							selectNote(note);
						else
						{
							trace('tryin to delete note...');
							deleteNote(note);
						}
					}
				});
			}
			else {
				if (isInGrid()) {
					trace('added note!');
					addNote();
				}
			}
		}

		if (isInGrid()) {
			dummyArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
			dummyArrow.y = FlxG.keys.pressed.SHIFT? FlxG.mouse.y : Math.floor(FlxG.mouse.y / GRID_SIZE) * GRID_SIZE;
		}

		if (FlxG.keys.justPressed.ENTER) {
			if (typingShit.hasFocus) 
				loadJson(_song.song.toLowerCase());
			else {
				lastSection = curSection;

				PlayState.SONG = _song;
				PlayState.storyDifficulty = backend.Defaults.difficultyArray.indexOf(curDifficulty);
				FlxG.sound.music.stop();
				vocals.stop();
				states.LoadingState.loadAndSwitchState(new PlayState());
			}
		}

		if (FlxG.keys.justPressed.E)
			changeNoteSustain(Conductor.stepCrochet);

		if (FlxG.keys.justPressed.Q)
			changeNoteSustain(-Conductor.stepCrochet);

		if (FlxG.keys.justPressed.TAB) {
			if (FlxG.keys.pressed.SHIFT) {
				UI_box.selected_tab -= 1;
				if (UI_box.selected_tab < 0)
					UI_box.selected_tab = 2;
			}
			else {
				UI_box.selected_tab += 1;
				if (UI_box.selected_tab >= 3)
					UI_box.selected_tab = 0;
			}
		}

		if (!typingShit.hasFocus) {

			if (FlxG.keys.justPressed.SPACE) {
				if (FlxG.sound.music.playing) {
					FlxG.sound.music.pause();
					vocals.pause();
				}
				else {
					vocals.play();
					FlxG.sound.music.play();
				}
			}

			if (FlxG.keys.justPressed.R) 
				resetSection(FlxG.keys.pressed.SHIFT);

			if (FlxG.sound.music.time < 0 || curStep < 0)
				FlxG.sound.music.time = 0;

			if (FlxG.mouse.wheel != 0) {
				FlxG.sound.music.pause();
				vocals.pause();

				FlxG.sound.music.time -= (FlxG.mouse.wheel * Conductor.stepCrochet * 0.4);
				vocals.time = FlxG.sound.music.time;
			}

			if (FlxG.keys.justPressed.W || FlxG.keys.justPressed.S) {
				FlxG.sound.music.pause();
				vocals.pause();

				var daTime:Float = FlxG.keys.pressed.SHIFT? 700 * FlxG.elapsed : Conductor.stepCrochet * 2;

				if (FlxG.keys.justPressed.W)
					FlxG.sound.music.time -= daTime;
				else
					FlxG.sound.music.time += daTime;

				vocals.time = FlxG.sound.music.time;
			}

			var shiftThing:Int = FlxG.keys.pressed.SHIFT? 4 : 1;
			if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D)
				changeSection(curSection + shiftThing);
			if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A)
				changeSection(curSection - shiftThing);
		}

		_song.bpm = tempBpm;

		displayInfo();
		super.update(elapsed);
	}

	function displayInfo() {
		var totalTime = FlxG.sound.music.length / 1000;
        var curTime = Conductor.songPosition / 1000;

		var title = songName + ' ($songDifficulty)\n';
		var time = '${Std.string(FlxMath.roundDecimal(curTime, 2))} / ${Std.string(FlxMath.roundDecimal(totalTime, 2))}';
		time += ' (${FlxStringUtil.formatTime(curTime)} / ${FlxStringUtil.formatTime(totalTime)})';
		var section = 'Section: $curSection';
		var stepInfo = '\nCurrent Step: $curStep\nCurrent Beat: $curBeat';
		infoTxt.text = '$title\n$time\n$section\n$stepInfo';
	}

	function changeNoteSustain(value:Float):Void {
		if (curSelectedNote != null) {
			if (curSelectedNote[2] != null) {
				curSelectedNote[2] += value;
				curSelectedNote[2] = Math.max(curSelectedNote[2], 0);

				var index = _song.notes[curSection].sectionNotes.indexOf(curSelectedNote);
				var stepLength = _song.notes[curSection].lengthInSteps;
				curRenderedNotes.members[index].changeSustainLength(curSelectedNote[2], stepLength);
			}
		}
		updateNoteUI();
	}

	function updateCurStep(useConductor:Bool = false):Int {
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}

		for (i in 0...Conductor.bpmChangeMap.length) {
			var songPosition = useConductor? Conductor.songPosition : FlxG.sound.music.time;
			if (songPosition > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		//curStep = lastChange.stepTime + Math.floor((Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet);
		curStep = lastChange.stepTime + Math.floor(FlxMath.roundDecimal(((Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet), 4));
		curBeat = Math.floor(curStep / 4);
		curMeasure = Math.floor(curBeat / 4);

		return curStep;
	}

	function resetSection(songBeginning:Bool = false):Void {
		FlxG.sound.music.pause();
		vocals.pause();

		// Basically old shit from changeSection???
		FlxG.sound.music.time = sectionStartTime();

		if (songBeginning)
		{
			FlxG.sound.music.time = 0;
			curSection = 0;
		}

		vocals.time = FlxG.sound.music.time;
		updateCurStep(true);

		updateGrid();
		updateSectionUI();
	}

	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void
	{
		trace('changing section' + sec);

		if (_song.notes[sec] != null)
		{
			curSection = sec;

			if (updateMusic)
			{
				FlxG.sound.music.pause();
				vocals.pause();

				FlxG.sound.music.time = sectionStartTime();
				vocals.time = FlxG.sound.music.time;
				updateCurStep(true);
			}

			updateGrid();
			updateSectionUI();
		}
	}

	function copySection(?sectionNum:Int = 1)
	{
		var daSec = FlxMath.maxInt(curSection, sectionNum);

		for (note in _song.notes[daSec - sectionNum].sectionNotes)
		{
			var strum = note[0] + Conductor.stepCrochet * (_song.notes[daSec].lengthInSteps * sectionNum);

			var copiedNote:Array<Dynamic> = [strum, note[1], note[2]];
			_song.notes[daSec].sectionNotes.push(copiedNote);
		}

		updateGrid();
	}

	function updateSectionUI():Void
	{
		var sec = _song.notes[curSection];

		stepperLength.value = sec.lengthInSteps;
		check_mustHitSection.checked = sec.mustHitSection;
		check_altAnim.checked = sec.altAnim;
		check_changeBPM.checked = sec.changeBPM;
		stepperSectionBPM.value = sec.bpm;

		updateHeads();
	}

	function updateHeads():Void {
		if (check_mustHitSection.checked) {
			leftIcon.animation.play(_song.player1);
			rightIcon.animation.play(_song.player2);
		}
		else {
			leftIcon.animation.play(_song.player2);
			rightIcon.animation.play(_song.player1);
		}
	}

	function updateNoteUI():Void {
		if (curSelectedNote != null)
			stepperSusLength.value = curSelectedNote[2];
	}

	function updateGrid():Void {
		remove(gridBG);
		var yaya:Int = 16;
		if (_song.notes[curSection].lengthInSteps > 0) yaya = _song.notes[curSection].lengthInSteps;
		gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 8, GRID_SIZE * yaya);
        add(gridBG);
		

		while (curRenderedNotes.members.length > 0) 
			curRenderedNotes.remove(curRenderedNotes.members[0], true);

		var sectionInfo:Array<Dynamic> = _song.notes[curSection].sectionNotes;

		if (_song.notes[curSection].changeBPM && _song.notes[curSection].bpm > 0) {
			Conductor.changeBPM(_song.notes[curSection].bpm);
			FlxG.log.add('CHANGED BPM!');
		}
		else {
			// get last bpm
			var daBPM:Float = _song.bpm;
			for (i in 0...curSection)
				if (_song.notes[i].changeBPM)
					daBPM = _song.notes[i].bpm;
			Conductor.changeBPM(daBPM);
		}

		for (i in sectionInfo) {
			var daNoteInfo = i[1];
			var daStrumTime = i[0];
			var daSus = i[2];

			var stepLength = _song.notes[curSection].lengthInSteps;
			var direction = daNoteInfo % 4;

			var noteX = Math.floor(daNoteInfo * GRID_SIZE);
			var noteY = Math.floor(getYfromStrum((daStrumTime - sectionStartTime()) % (Conductor.stepCrochet * stepLength)));
			
			var note:ChartNote = constructNote(daStrumTime, direction, daSus, stepLength);
			curRenderedNotes.add(note);
			note.setNoteGraphic(direction, _song.noteStyle);
			note.changeSustainLength(daSus, stepLength);
			
			note.setPosition(noteX, noteY);
		}
	}

	private function constructNote(daStrumTime, direction, daSus, stepLength):ChartNote {
		var dummy:ChartNote = recyclableNotes.getFirstAvailable();
		if (dummy != null) {
			dummy.revive();
			recyclableNotes.remove(dummy);
		}
		else
			dummy = new ChartNote(daStrumTime, direction, daSus, stepLength);

		dummy.note.strumTime = daStrumTime;
		if (dummy.note.strumTime < 0) dummy.note.strumTime = 0;
		return dummy;
	}

	private function addSection(lengthInSteps:Int = 16):Void {
		var sec:SwagSection = {
			lengthInSteps: lengthInSteps,
			bpm: _song.bpm,
			changeBPM: false,
			mustHitSection: true,
			sectionNotes: [],
			typeOfSection: 0,
			altAnim: false
		};

		_song.notes.push(sec);
	}

	function selectNote(note:ChartNote):Void {
		var swagNum:Int = 0;

		for (i in _song.notes[curSection].sectionNotes) {
			if (i.strumTime == note.note.strumTime && i.noteData % 4 == note.note.noteData)
				curSelectedNote = _song.notes[curSection].sectionNotes[swagNum];
			swagNum++;
		}

		updateGrid();
		updateNoteUI();
	}

	function deleteNote(note:ChartNote):Void {
		for (i in _song.notes[curSection].sectionNotes) {
			if (i[0] == note.note.strumTime && i[1] % 4 == note.note.noteData) 
				_song.notes[curSection].sectionNotes.remove(i);
		}

		updateGrid();
	}

	function clearSection():Void {
		_song.notes[curSection].sectionNotes = [];

		updateGrid();
	}

	function clearSong():Void {
		for (daSection in 0..._song.notes.length)
			_song.notes[daSection].sectionNotes = [];

		updateGrid();
	}

	private function addNote():Void {
		var noteStrum = getStrumTime(dummyArrow.y) + sectionStartTime();
		var noteData = Math.floor(FlxG.mouse.x / GRID_SIZE);
		var noteSus = 0;

		_song.notes[curSection].sectionNotes.push([noteStrum, noteData, noteSus]);

		curSelectedNote = _song.notes[curSection].sectionNotes[_song.notes[curSection].sectionNotes.length - 1];

		if (FlxG.keys.pressed.CONTROL)
			_song.notes[curSection].sectionNotes.push([noteStrum, (noteData + 4) % 8, noteSus]);

		trace('$noteStrum | $curSection');

		updateGrid();
		updateNoteUI();

		//autosaveSong();
	}

	function getStrumTime(yPos:Float):Float {
		return FlxMath.remapToRange(yPos, gridBG.y, gridBG.y + gridBG.height, 0, 16 * Conductor.stepCrochet);
	}

	function getYfromStrum(strumTime:Float):Float {
		return FlxMath.remapToRange(strumTime, 0, 16 * Conductor.stepCrochet, gridBG.y, gridBG.y + gridBG.height);
	}

	function getNotes():Array<Dynamic> {
		var noteData:Array<Dynamic> = [];

		for (i in _song.notes)
			noteData.push(i.sectionNotes);

		return noteData;
	}

	function getDifficulty(name:String):String {
		if (!name.contains('-')) return 'Normal'; // assume it is just the default difficulty

		var choppedName:Array<String> = name.split('-');
		var finalName = choppedName[choppedName.length - 1];
		trace(finalName.toLowerCase());
		if (!['easy', 'hard'].contains(finalName.toLowerCase())) return 'Normal';

		return FlxStringUtil.toTitleCase(finalName);
	}

	function isInGrid():Bool {
		return FlxG.mouse.x > gridBG.x
		&& FlxG.mouse.x < gridBG.x + GRID_SIZE * 8
		&& FlxG.mouse.y > gridBG.y
		&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * _song.notes[curSection].lengthInSteps);
	}

	function loadJson(song:String):Void {
		var dif = curDifficulty.toLowerCase() == 'normal'? '' : curDifficulty.toLowerCase();
		if (!openfl.utils.Assets.exists(Paths.json('songs/$song/$song-$dif'))) return;
		_songID = '$song-$dif';
		PlayState.SONG = Song.loadFromJson(_songID, song);
		states.LoadingState.loadAndSwitchState(new ChartingState());
	}

	function loadAutosave():Void {
		PlayState.SONG = Song.parseJSONshit(FlxG.save.data.autosave);
		states.LoadingState.loadAndSwitchState(new ChartingState());
	}

	function autosaveSong():Void {
		FlxG.save.data.autosave = Json.stringify({
			"song": _song
		});
		FlxG.save.flush();
	}

	private function saveLevel() {
		var json = {
			"song": _song
		};

		var data:String = Json.stringify(json);

		if ((data != null) && (data.length > 0)) {
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), _song.song.toLowerCase() + ".json");
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}
}
