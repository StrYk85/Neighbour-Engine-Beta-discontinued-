package debug;

import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;

class InterfaceUtil {
    public static function createDropDown(x:Float, y:Float, name:String, array:Array<String>, callBack:String -> Void, ?selectedLabel:Dynamic):FlxSpriteGroup {
        var dropdownGroup:FlxSpriteGroup = new FlxSpriteGroup();
        var dropper = new FlxUIDropDownMenu(x, y, FlxUIDropDownMenu.makeStrIdLabelArray(array, true), callBack);
		if (selectedLabel != null) dropper.selectedLabel = selectedLabel;

        var label = new FlxText(dropper.x, dropper.y - 15, 64, name);
        dropdownGroup.add(dropper);
        dropdownGroup.add(label);

        return dropdownGroup;
    }
}