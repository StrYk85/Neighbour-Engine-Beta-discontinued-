package ui;

import play.Conductor;
import play.Conductor.BPMChangeEvent;
import ui.DefaultText;

class MusicBeatState extends flixel.addons.ui.FlxUIState
{
	public function new()
	{
		super();
	}
	
	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	private var curMeasure:Int = 0;
	private var controls(get, never):Controls;

	private var leftWatermark:DefaultText;

	inline function get_controls():Controls
		return backend.PlayerSettings.player1.controls;

	override function create() {
		super.create();
		leftWatermark = new DefaultText(5, FlxG.height - 20, '');
		leftWatermark.scrollFactor.set();
		add(leftWatermark);

		Paths.clearUnusedMemory();
	}

	override function update(elapsed:Float) {
		var oldStep:Int = curStep;

		curStep = updateCurStep();
		if (oldStep != curStep && curStep >= 0) stepHit();

		super.update(elapsed);
	}

	private function updateCurStep():Int {
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		
		for (i in 0...Conductor.bpmChangeMap.length) {
			if (Conductor.songPosition >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		//curStep = lastChange.stepTime + Math.floor((Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet);
		curStep = lastChange.stepTime + Math.floor(flixel.math.FlxMath.roundDecimal(((Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet), 4));
		updateBeat();

		return curStep;
	}

	private function updateBeat():Void {
		curBeat = Math.floor(curStep / 4);
	}

	private function updateMeasure():Void {
		curMeasure = Math.floor(curBeat / 4);
	}

	public function stepHit():Void {
		if (curStep % 4 == 0) beatHit();
	}

	public function beatHit():Void {
        if (curBeat % 4 == 0) measureHit();
    }

    public function measureHit():Void {
    }
}
