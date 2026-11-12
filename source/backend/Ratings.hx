package backend;

import haxe.ds.StringMap;
import flixel.math.FlxMath;
import flixel.util.FlxStringUtil;

class Ratings
{
    public static function calculateRating(noteDiff:Float, ?customSafeZone:Float):String // Generate a judgement through some timing shit
    {
        var customTimeScale = play.Conductor.timeScale;

        if (customSafeZone != null)
            customTimeScale = customSafeZone / 166;

        var rating = checkRating(noteDiff, customTimeScale);
        return rating;
    }

    public static function checkRating(ms:Float, ts:Float)
    {
        var rating = "sick";

        var ratingYaya = [
            'shit' => 180,
            'bad' => 135,
            'good' => 90,
            'sick' => 45
        ];

        if (ms <= ratingYaya.get('shit') * ts && ms >= ratingYaya.get('bad') * ts)
            rating = "shit";
        if (ms < ratingYaya.get('bad') * ts && ms >= ratingYaya.get('good') * ts) 
            rating = "bad";
        if (ms < ratingYaya.get('good') * ts && ms >= ratingYaya.get('sick') * ts)
            rating = "good";
        if (ms < ratingYaya.get('sick') * ts && ms >= ratingYaya.get('sick') * -ts)
            rating = "sick";
        if (ms > ratingYaya.get('good') * -ts && ms <= ratingYaya.get('sick') * -ts)
            rating = "good";
        if (ms > ratingYaya.get('bad') * -ts && ms <= ratingYaya.get('good') * -ts)
            rating = "bad";
        if (ms > ratingYaya.get('shit') * -ts && ms <= ratingYaya.get('bad') * -ts)
            rating = "shit";
        
        return rating;
    }

    public static function calculateRanking(score:Int, misses:Int, accuracy:Float):String {
        var scorePortion:String = 'Score: ${FlxStringUtil.formatMoney(score, false)}';
        var missPortion:String = (FlxG.save.data.ghost? 'Combo Breaks: ' : 'Misses: ') + misses;
        var accuracyPortion:String = 'Accuracy: ${FlxMath.roundDecimal(accuracy, 2)}%';
        return '$scorePortion | $missPortion | $accuracyPortion';
    }
}
