package debug;

import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import play.notes.Note;
import play.notes.NoteStyle;
import graphics.FunkinSprite;

class ChartNote extends FlxSpriteGroup {
    private var GRID_SIZE:Int = 40;
    public var noteStyle:String = 'default';

    public var note:Note;
    public var sustainNote:FunkinSprite;

    public function new(strumTime:Float, direction:Int, sustainLength:Float, stepLength:Float) {
        super();

        note = new Note(strumTime, direction, null, false, true);

        var sustainWidth:Int = 8;
        sustainNote = new FunkinSprite((GRID_SIZE / 2) - (sustainWidth / 2), GRID_SIZE);
		sustainNote.makeSolid(sustainWidth, 0, -1);

        add(sustainNote);
        add(note);
    }

    public function setNoteGraphic(dir:Int, style:String):Void {
        if (style != noteStyle || note.noteData != dir) {
            NoteStyle.applyToNote(note, style);
            note.animation.play('scroll');
            noteStyle = style;
        }
        note.noteData = dir;
        note.setGraphicSize(GRID_SIZE, GRID_SIZE);
		note.updateHitbox();
        note.setPosition(0, 0);
    }

    public function changeSustainLength(value:Float, stepLength:Float):Void {
        if (value <= 0) value = 0;
        sustainNote.scale.y = Math.floor(FlxMath.remapToRange(value, 0, play.Conductor.stepCrochet * stepLength, 0, GRID_SIZE * stepLength));
        sustainNote.color = backend.Defaults.NOTE_COLORS[note.noteData];
		sustainNote.updateHitbox();
    }
}