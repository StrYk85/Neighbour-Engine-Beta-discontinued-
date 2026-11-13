package backend;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;

import openfl.Assets;
import openfl.media.Sound;

import openfl.utils.AssetType;
import openfl.system.System;
import openfl.utils.Assets as OpenFlAssets;

class Paths {
	static function getPath(file:String, type:AssetType, ?library:Null<String> = null) {
		if (library != null) return getLibraryPath(file, library);

		var levelPath:String = getLibraryPathForce(file, 'shared');
		if (OpenFlAssets.exists(levelPath, type))
			return levelPath;

		return getPreloadPath(file);
	}

	public static var dumpExclusions:Array<String> =
	[
		'assets/audio/music/freakyMenu.${Defaults.SOUND_EXT}',
		'assets/audio/music/breakfast.${Defaults.SOUND_EXT}',
	];

	public static function excludeAsset(key:String) {
		if (!dumpExclusions.contains(key)) dumpExclusions.push(key);
	}

	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static var currentTrackedSounds:Map<String, Sound> = [];

	public static var localTrackedAssets:Array<String> = [];

	public static function clearUnusedMemory() {
		for (key in currentTrackedAssets.keys()) {
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key)) {
				var obj:Null<FlxGraphic> = currentTrackedAssets.get(key);
				if (obj != null) {
					clearGraphic(obj, key);
					currentTrackedAssets.remove(key);
				}
			}
		}
		// run the garbage collector for good measure lmfao
		System.gc();
	}

	public static function clearStoredMemory() {
		// clear anything not in the tracked assets list
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys()) {
			var obj:Null<FlxGraphic> = FlxG.bitmap._cache.get(key);
			if (!currentTrackedAssets.exists(key)) 
				clearGraphic(obj, key);
		}

		for (key in currentTrackedSounds.keys()) {
			var sound:Null<Sound> = currentTrackedSounds.get(key);
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key)) {
				if (sound != null) {
					clearSound(sound, key);
					currentTrackedSounds.remove(key);
				}
			}
		}

		// flags everything to be cleared out next unused memory clear
		localTrackedAssets.resize(0);

		#if !html5 
		Assets.cache.clear('audio/songs'); 
		Assets.cache.clear('audio/music'); 
		#end
	}

	public static function clearGraphic(graphic:FlxGraphic, graphicKey:Null<String>) {
		if (graphic == null) return;

		FlxG.bitmap.remove(graphic);
        graphic.persist = false;
        graphic.destroy();
        Assets.cache.clear(graphicKey);
	}

	public static function clearSound(sound:Sound, soundKey:Null<String>) {
		if (sound == null) return;
		Assets.cache.removeSound(soundKey);
		Assets.cache.clear(soundKey);
	}

	static public function getLibraryPath(file:String, library = 'preload') {
		return if (library == 'preload' || library == 'default') getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String) {
		return '$library:assets/$library/$file';
	}

	inline static function getPreloadPath(file:String) {
		return 'assets/$file';
	}

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String) {
		return getPath(file, type, library);
	}

	inline static public function txt(key:String, ?library:String) {
		return getPath('data/$key.txt', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String) {
		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function json(key:String, ?library:String) {
		return getPath('data/$key.json', TEXT, library);
	}

	static public function sound(key:String, ?library:String) {
		//return getPath('sounds/$key.$SOUND_EXT', SOUND, library);
		var daPath = getPath('audio/sounds/$key.${Defaults.SOUND_EXT}', SOUND, library);

		if (!currentTrackedSounds.exists(daPath)) {
			var sound:Null<Sound> = Assets.getSound(daPath, true);
			if (sound != null)
				currentTrackedSounds.set(daPath, sound);
		}

		return currentTrackedSounds.get(daPath);
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String) {
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String) {
		return getPath('audio/music/$key.${Defaults.SOUND_EXT}', MUSIC, library);
	}

	inline static public function voices(song:String) {
		var songLowercase = StringTools.replace(song, ' ', '-').toLowerCase();
		return getPath('audio/songs/${songLowercase}/Voices.${Defaults.SOUND_EXT}', SOUND);
	}

	inline static public function inst(song:String) {
		var songLowercase = StringTools.replace(song, ' ', '-').toLowerCase();
		return getPath('audio/songs/${songLowercase}/Inst.${Defaults.SOUND_EXT}', SOUND);
	}

	inline static public function image(key:String, ?library:String) {
		return getPath('images/$key.png', IMAGE, library);
	}

	inline static public function font(key:String) {
		return 'assets/fonts/$key';
	}

	inline static public function getSparrowAtlas(key:String, ?library:String) {
		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));
	}

	inline static public function getPackerAtlas(key:String, ?library:String) {
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));
	}
}
