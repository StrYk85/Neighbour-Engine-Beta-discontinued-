package;

import haxe.Json;
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import flixel.util.FlxStringUtil;
import flixel.util.FlxColor;

using StringTools;

typedef AnimationData = {
    var name:String;
    var prefix:String;
	var offsets:Array<Float>;
    var framerate:Int;
    var loop:Bool;
    var indices:Array<Int>;
	var loopIndices:Array<Int>;
}

class Character extends FunkinSprite {
	public var animOffsets:Map<String, Array<Dynamic>> = new Map<String, Array<Dynamic>>();
	public var cameraOffsets:Array<Float> = [0, 0];
	public var stageOffsets:Array<Float> = [0, 0];

	public var isPlayer:Bool = false;
	private var forcedPlayer:Bool = false;

	public var curCharacter:String = 'bf';
	public var noteStyle:String = 'default';
	public var charIcon:String = 'default';
	public var iconColor:String;

	public var holdTimer:Float = 0;
	public var singTime:Float = 4;

	public var debugMode:Bool = false;

	public function new(x:Float, y:Float, ?character:String = "bf", ?isPlayer:Bool = false) {
		super(x, y, character);
		curCharacter = character;
		this.isPlayer = isPlayer;

		if (!OpenFlAssets.exists(Paths.json('characters/' + curCharacter))) curCharacter = 'bf';
		var rawJson = Assets.getText(Paths.json('characters/' + curCharacter));
		var daJson = Json.parse(rawJson);

		frames = Paths.getSparrowAtlas(daJson.assetPath);
		var animations:Array<AnimationData> = daJson.animations;

		for (anim in animations) {
			if (anim.name == 'danceLeft' || anim.name == 'danceRight') shouldAlternate = true;

			if (anim.indices != null) animation.addByIndices(anim.name, anim.prefix, anim.indices, '', anim.framerate ?? 24, anim.loop ?? false);
			else animation.addByPrefix(anim.name, anim.prefix, anim.framerate ?? 24, anim.loop ?? false);
			if (anim.offsets != null) addOffset(anim.name, anim.offsets[0] ?? 0.0, anim.offsets[1] ?? 0.0);
			else addOffset(anim.name, 0, 0);

			if (anim.loopIndices != null) {
				animation.addByIndices(anim.name + '-loop', anim.prefix, anim.loopIndices, '', anim.framerate ?? 24, true);
				animOffsets[anim.name + '-loop'] = animOffsets[anim.name];
			}
		}

		var camOffs:Array<Float> = isPlayer? daJson.playerCameraOffsets : daJson.cameraOffsets;
		var stageOffs:Array<Float> = isPlayer? daJson.playerOffsets : daJson.offsets;

		if (camOffs != null) 
			cameraOffsets = [camOffs[0] ?? 0, camOffs[1] ?? 0];

		if (stageOffs != null) 
			stageOffsets = [stageOffs[0] ?? 0, stageOffs[1] ?? 0];

		flipX = daJson.flipX ?? false;
		antialiasing = daJson.antialiasing ?? true;
		noteStyle = daJson.noteStyle ?? 'default';
		charIcon = daJson.icon ?? curCharacter;
		iconColor = daJson.iconColor;

		if (isPlayer && !daJson.nativelyPlayable) {
			flipX = !flipX;
			forcedPlayer = true;
		}

		animation.onFinish.add(function(animName:String) if (animation.exists(animName + '-loop')) playAnim(animName + '-loop', true, false, 0));
		playAnim(shouldAlternate? 'danceRight' : 'idle', true);
	}

	override function update(elapsed:Float) {
		if (!debugMode) {
			if (animation.curAnim.name.startsWith('sing')) holdTimer += elapsed;
			else if (isPlayer) holdTimer = 0;

			if (!isPlayer && holdTimer >= (Conductor.stepCrochet / 1000) * singTime) {
				dance();
				holdTimer = 0;
			}
		}
		super.update(elapsed);
	}

	override function dance() {
		if (!debugMode) super.dance();
	}

	public function taunt():Void {
		var animToPlay:String = '';
		// All possible animations that can be considered as taunts, this includes the up pose because why not LOL
		for (anim in ['hey', 'cheer', 'taunt']) {
			if (animation.exists(anim)) {
				animToPlay = anim;
				break;
			}
		}
		if (animToPlay == '') {
			dance();
			return;
		}
		playAnim(animToPlay, true);
	}

	public function sing(direction:Int, miss:Bool = false, reversed:Bool = false, frame:Int = 0):Void {
		var noteDirections = Defaults.NOTE_DIRECTIONS;
		var directionToSing = noteDirections[direction].toUpperCase();
		if (forcedPlayer) {
			switch (directionToSing) {
				case 'LEFT': directionToSing = 'RIGHT';
				case 'RIGHT': directionToSing = 'LEFT';
			}
		}
		var yaya:Bool = false;
		if (miss) {
			if (animation.exists('sing${directionToSing}miss')) directionToSing += 'miss';
			else yaya = true;
		}
		playAnim('sing$directionToSing', true, reversed, frame);
		holdTimer = 0;
		if (yaya) color = Defaults.MISS_COLOR;
	}

	override function playAnim(animationName:String, force:Bool = false, reversed:Bool = false, frame:Int = 0):Void {
		super.playAnim(animationName, force, reversed, frame);

		var daOffset = animOffsets.get(animationName);
		if (animOffsets.exists(animationName))
			offset.set(daOffset[0], daOffset[1])
		else 
			offset.set();

		color = defaultColor;
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0) {
		animOffsets[name] = [x, y];
	}

	private var defaultColor:FlxColor = FlxColor.WHITE;

	override function set_color(value:FlxColor):Int {
		if (value != Defaults.MISS_COLOR) defaultColor = value;
		return super.set_color(value);
	}
}