package stage;

import flixel.FlxG;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
using StringTools;

class SongSetup {
    public static function preCreate() {

    }

    public static function postCreate() {
        switch (PlayState.SONG.song) {
            case 'Tutorial':
                FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
        }
    }

    public static function update() {
        
    }

    public static function beatHit(curBeat:Int):Void {
        switch (PlayState.SONG.song) {
            case 'Tutorial':
                if (curBeat > 16 && curBeat < 48 && curBeat % 16 == 15) {
                    PlayState.instance.boyfriend.taunt();
                    PlayState.instance.dad.taunt();
                }
            case 'Bopeebo':
                if (curBeat % 8 == 7) {
                    PlayState.instance.boyfriend.taunt();
                    PlayState.instance.gf.taunt();
                }
            case 'Fresh':
                switch (curBeat) {
                    case 16:
                        PlayState.instance.camZooming = true;
                        PlayState.instance.gfSpeed = 2;
                    case 48:
                        PlayState.instance.gfSpeed = 1;
                    case 80:
                        PlayState.instance.gfSpeed = 2;
                    case 112:
                        PlayState.instance.gfSpeed = 1;
			}
            case 'Philly Nice':
                if (curBeat != 184 && curBeat != 216 && curBeat % 16 == 8)
                    PlayState.instance.gf.taunt();
            case 'Blammed':
                if (curBeat > 30 && curBeat < 190 && (curBeat < 90 || curBeat > 128) && curBeat % 4 == 2)
                    PlayState.instance.gf.taunt();
        }
    }

    public static function stepHit(curStep:Int):Void {
        
    }
}