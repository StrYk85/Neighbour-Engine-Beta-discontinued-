package play.stage;

import haxe.Json;
import lime.utils.Assets;
import backend.AnimationData;

class Character extends Bopper {
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

	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false) {
		super(x, y, character);
		curCharacter = character;
		this.isPlayer = isPlayer;

		if (!openfl.utils.Assets.exists(Paths.json('characters/' + curCharacter))) curCharacter = 'bf';
		var daJson = Json.parse(Assets.getText(Paths.json('characters/' + curCharacter)));

		loadSparrow(daJson.assetPath);
		var animations:Array<AnimationData> = daJson.animations;

		for (anim in animations) {
			if (anim.name == 'danceLeft' || anim.name == 'danceRight') shouldAlternate = true;
			addAnimation(anim.name, anim.prefix, anim.indices, anim.offsets, anim.framerate, anim.loop);
			if (anim.loopIndices != null) addAnimation('${anim.name}-loop', anim.prefix, anim.loopIndices, anim.offsets, anim.framerate, anim.loop);
		}

		var camOffs:Array<Float> = isPlayer? daJson.playerCameraOffsets : daJson.cameraOffsets;
		if (camOffs != null) cameraOffsets = [camOffs[0] ?? 0, camOffs[1] ?? 0];

		var stageOffs:Array<Float> = isPlayer? daJson.playerOffsets : daJson.offsets;
		if (stageOffs != null) stageOffsets = [stageOffs[0] ?? 0, stageOffs[1] ?? 0];

		flipX = daJson.flipX ?? false;
		antialiasing = daJson.antialiasing ?? true;
		noteStyle = daJson.noteStyle ?? 'default'; // why did i add this?
		charIcon = daJson.icon ?? curCharacter;
		iconColor = daJson.iconColor;

		if (isPlayer && !daJson.nativelyPlayable) {
			flipX = !flipX;
			forcedPlayer = true;
		}

		animation.onFinish.add(function(animName:String) if (animationExists(animName + '-loop')) playAnimation(animName + '-loop', true, false, 0));
		playAnimation(shouldAlternate? 'danceRight' : 'idle', true);
	}

	override function update(elapsed:Float) {
		if (logicUpdate) {
			if (isSinging()) holdTimer += elapsed;
			else if (isPlayer) holdTimer = 0;

			if (!isPlayer && holdTimer >= (Conductor.stepCrochet / 1000) * singTime) {
				dance();
				holdTimer = 0;
			}
		}
		super.update(elapsed);
	}

	public function taunt():Void {
		var animToPlay:String = '';
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

	public function singDirection(direction:Int, miss:Bool = false, reversed:Bool = false, frame:Int = 0):Void {
		var noteDirections = forcedPlayer? backend.Defaults.NOTE_DIRECTIONS_SWAP : backend.Defaults.NOTE_DIRECTIONS;
		var directionToSing = noteDirections[direction].toUpperCase();
		
		if (miss && animation.exists('sing${directionToSing}miss')) directionToSing += 'miss';
		playAnim('sing$directionToSing', true, reversed, frame);
		holdTimer = 0;
	}

	public function sing(direction:Int, miss:Bool = false, reversed:Bool = false, frame:Int = 0):Void {
		singDirection(direction, miss, reversed, frame);
	}

	public function isSinging():Bool {
		return animationStartsWith('sing');
	}
}