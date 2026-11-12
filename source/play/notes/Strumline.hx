package play.notes;

import flixel.math.FlxRect;
import flixel.FlxSprite;
import flixel.util.FlxSort;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.math.FlxMath;
import play.Section.SwagSection;
import play.Song.SwagSong;
import play.PlayState;

using StringTools;

class Strumline extends FlxSpriteGroup {
    private var unspawnNotes:Array<Note> = [];

    public static var arrowAmount:Int = 4;
    public static final swagWidth:Float = 160 * 0.7;

    public var strumNotes:FlxTypedSpriteGroup<FlxSprite> = new FlxTypedSpriteGroup<FlxSprite>();
    public var notes:FlxTypedSpriteGroup<Note> = new FlxTypedSpriteGroup<Note>();
    //public var covers:FlxTypedSpriteGroup<HoldCover> = new FlxTypedSpriteGroup<HoldCover>();
    //public var splashes:FlxTypedSpriteGroup<NoteSplash> = new FlxTypedSpriteGroup<NoteSplash>();

    public var bot:Bool = false;
    public var curSpeed(default, set):Float = 1;
    private var killRadius:Float = 350;
    public var noteStyle:String;

    public var onNoteMiss(default, null):FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();
    public var onNoteHit(default, null):FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();

    function set_curSpeed(value:Float):Float {
        curSpeed = value ?? 1;
        killRadius = Math.max(Conductor.stepCrochet, 350 / curSpeed);
        return curSpeed;
    }

    public function new(bot:Bool = false, noteStyle:String) {
        super();
        this.bot = bot;
        this.noteStyle = noteStyle;

        add(strumNotes);
        add(notes);
        //add(covers);
        //add(splashes);

        for (i in 0...arrowAmount) generateStaticArrow(i);
    }

    public function generateNotes(daNotes:Array<Dynamic>) {
        for (noteParams in daNotes) {
            var strumTime:Float = noteParams[0] + FlxG.save.data.offset + (PlayState.songOffset ?? 0);
            if (strumTime < 0) strumTime = 0;

			var oldNote:Note = unspawnNotes[Std.int(unspawnNotes.length - 1)];
            var direction:Int = Std.int(noteParams[1] % arrowAmount);

			var swagNote:Note = new Note(strumTime, direction, oldNote ?? null, false);
            swagNote.scrollFactor.set();
			unspawnNotes.push(swagNote);

            if (oldNote != null) oldNote.nextNote = swagNote;
			for (hold in 0...Math.floor(noteParams[2] / Conductor.stepCrochet)) {
                oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

				var holdNote:Note = new Note(strumTime + (Conductor.stepCrochet * hold) + Conductor.stepCrochet / 2, direction, oldNote, true);
                holdNote.scrollFactor.set();
				unspawnNotes.push(holdNote);

                if (oldNote != null) oldNote.nextNote = holdNote;
			}
		}
        trace('generated notes for the '+ (bot? 'opponent' : 'player') +' strumline');
		unspawnNotes.sort(sortByShit);
	}

    function sortByShit(Obj1:Note, Obj2:Note):Int {
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

    public function generateStaticArrow(num:Int) {
		var babyArrow:FlxSprite = new FlxSprite(0, this.y);
        var dir = num % arrowAmount;
        NoteStyle.applyToStrumNote(babyArrow, dir, noteStyle);

        babyArrow.x += swagWidth * dir;
        babyArrow.ID = dir;

		if (bot) babyArrow.animation.onFinish.add((animName:String) -> playStatic(dir));
        strumNotes.add(babyArrow);

        //if (!bot) {
        //    var splash = new NoteSplash(dir, babyArrow);
        //    splashes.add(splash);
        //    splash.visible = false;
        //}

        //var cover = new HoldCover(dir, babyArrow);
        //covers.add(cover);
        //cover.visible = false;

        playStatic(num);
    }

    public function fadeInArrows() {
        for (i => babyArrow in strumNotes.members) {
            babyArrow.y -= 10;
            babyArrow.alpha = 0;
            FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
        }
    }

    public function setSpeed(value:Float) {
        curSpeed = value;
    }

    public function prepareNotes() {
        if (unspawnNotes[0] != null) {
			if (unspawnNotes[0].strumTime - Conductor.songPosition < 1500) {
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}
    }

    public function updateNotes() {
        prepareNotes();

        notes.forEachAlive(function(daNote:Note) {
            daNote.updateNote(bot);

            var heightStuff:Bool = daNote.tooLate;
            var downscrollStuff:Int = FlxG.save.data.downscroll? -1 : 1;

            daNote.active = !heightStuff;
            daNote.visible = !heightStuff;

            daNote.y = strumNotes.members[daNote.noteData].y - (Conductor.songPosition - daNote.strumTime) * (0.45 * curSpeed * downscrollStuff);
            daNote.x = strumNotes.members[daNote.noteData].x;

            if (daNote.isSustainNote) {
                daNote.x += (swagWidth - daNote.width) / 2;
                daNote.x = FlxMath.roundDecimal(daNote.x, 2);

                if (daNote.animation.curAnim?.name != 'holdend') {
                    daNote.scale.y = daNote.noteScale * Conductor.stepCrochet / 100 * 1.5 * curSpeed;
                    daNote.updateHitbox();
                }

                var center = strumNotes.members[daNote.noteData].y + swagWidth / 2;
                if (daNote.wasGoodHit || daNote.prevNote.wasGoodHit && !daNote.canBeHit) {
                    var swagRect:FlxRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);

                    if (downscrollStuff < 0 && (daNote.y - daNote.offset.y * daNote.scale.y + daNote.height) >= center) {
                        swagRect.height = (center - daNote.y) / daNote.scale.y;
                        swagRect.y = daNote.frameHeight - swagRect.height;
                    }
                    else if ((daNote.y + daNote.offset.y * daNote.scale.y) <= center) {
                        swagRect.y = (center - daNote.y) / daNote.scale.y;
                        swagRect.height -= swagRect.y;
                    }

                    daNote.clipRect = swagRect;
                }
                else if (daNote.animation.curAnim?.name == 'holdend' && downscrollStuff < 0) {
                    daNote.updateHitbox();
                    daNote.offset.y -= daNote.frameHeight;
                }
            }
            else {
                daNote.angle = strumNotes.members[daNote.noteData].angle;
            }

            if (Conductor.songPosition > killRadius + daNote.strumTime) {
                if (daNote.tooLate || daNote.wasGoodHit) 
                    byeNote(daNote, true);
			}

            if (bot && daNote.wasGoodHit && !daNote.hasBeenMissed) {
                onNoteHit.dispatch(daNote);
                hitNote(daNote);
                daNote.hasBeenMissed = true;
            }

            if (daNote.tooLate && !daNote.hasBeenMissed) {
                onNoteMiss.dispatch(daNote);
                daNote.hasBeenMissed = true;
            }
		});
    }

    public function hitNote(note:Note) {
        if (note == null) return;
        var dir = (note.noteData % arrowAmount);
        note.wasGoodHit = true;
        playConfirm(dir);

        //if (note.sustainParent) {
        //    covers.members[dir].playStart();
        //    covers.members[dir].visible = true;
        //}
        
        //if (note.isSustainNote) {
        //    covers.members[dir].visible = true;
        //    if (note.animation.curAnim?.name != 'idle') 
        //        covers.members[dir].playIdle();
        //    if (note.animation.curAnim?.name == 'holdend') {
        //        if (!bot) covers.members[dir].playEnd();
        //        else covers.members[dir].visible = false;
        //    }
        //}

        onNoteHit.dispatch(note);
        byeNote(note, false);
    }

    public function byeNote(note:Note, ?force:Bool = false) {
        note.active = false;
        note.visible = note.isSustainNote;
        if (!note.isSustainNote || force) {
            notes.remove(note, true);
            note.destroy();
        }
    }

    public function playStrumAnim(dir:Int, name:String) {
        strumNotes.members[dir].animation.play(name, true);
        strumNotes.members[dir].centerOffsets();
    }

    public function playStatic(dir:Int) {
        playStrumAnim(dir, 'static');
        //if (covers.members[dir].animation.curAnim?.name != 'end') covers.members[dir].visible = false;
    }

    public function playPress(dir:Int) {
        playStrumAnim(dir, 'pressed');
        //if (covers.members[dir].animation.curAnim?.name != 'end') covers.members[dir].visible = false;
    }

    public function playConfirm(dir:Int) {
        playStrumAnim(dir, 'confirm');
        if (noteStyle != 'pixel') {
            strumNotes.members[dir].offset.x -= 13;
            strumNotes.members[dir].offset.y -= 13;
        }
    }
}