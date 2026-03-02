package objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

class ColorPicker extends FlxSpriteGroup {
    public var selectedHue:Float = 0;
    public var selectedColor:FlxColor = FlxColor.WHITE;
    
    public var onColorChanged:FlxColor->Void = null;
    
    var isDragging:Bool = false;
    var gradient:FlxSprite;
    var cursor:FlxSprite;
    var pickerWidth:Int;
    var pickerHeight:Int;
    
    public function new(x:Float, y:Float, width:Int, height:Int) {
        super(x, y);
        
        pickerWidth = width;
        pickerHeight = height;
        
        gradient = new FlxSprite();
        gradient.makeGraphic(width, height, FlxColor.TRANSPARENT);
        add(gradient);
        
        cursor = new FlxSprite();
        cursor.makeGraphic(12, 12, FlxColor.TRANSPARENT);
        FlxSpriteUtil.drawCircle(cursor, 6, 6, 4, FlxColor.TRANSPARENT, {thickness: 2, color: FlxColor.WHITE});
        FlxSpriteUtil.drawCircle(cursor, 6, 6, 5, FlxColor.TRANSPARENT, {thickness: 1, color: FlxColor.BLACK});
        add(cursor);
        
        updateGradient(0);
    }
    
    override function update(elapsed:Float) {
        super.update(elapsed);
        
        if (FlxG.mouse.overlaps(gradient, cameras[0]) && FlxG.mouse.justPressed) {
            isDragging = true;
            cursor.visible = true;
            updateSelectedColor();
        }
        
        if (isDragging && (FlxG.mouse.pressed && FlxG.mouse.justMoved)) {
            updateSelectedColor();
        }
        
        if (FlxG.mouse.justReleased) {
            isDragging = false;
        }
    }
    
    var lastCursorX:Float = 0;
    var lastCursorY:Float = 0;
    function updateSelectedColor() {
        var localX:Float = FlxG.mouse.getViewPosition(cameras[0]).x - x;
        var localY:Float = FlxG.mouse.getViewPosition(cameras[0]).y - y;
        
        lastCursorX = Math.max(0, Math.min(localX, pickerWidth - 1));
        lastCursorY = Math.max(0, Math.min(localY, pickerHeight - 1));
        
        cursor.x = x + lastCursorX - 6;
        cursor.y = y + lastCursorY - 6;
        
        selectedColor = getColorAt(Std.int(lastCursorX), Std.int(lastCursorY));
        
        if (onColorChanged != null) {
            onColorChanged(selectedColor);
        }
    }
    
    public function getColorAt(x:Int, y:Int):FlxColor {
        var saturation:Float = x / pickerWidth;
        var brightness:Float = 1.0 - (y / pickerHeight);
        return FlxColor.fromHSB(selectedHue, saturation, brightness);
    }
    
    public function updateGradient(hue:Float) {
        selectedHue = hue;
        gradient.pixels.lock();
        for (py in 0...pickerHeight) {
            for (px in 0...pickerWidth) {
                var saturation:Float = px / pickerWidth;
                var brightness:Float = 1.0 - (py / pickerHeight);
                var color:FlxColor = FlxColor.fromHSB(hue, saturation, brightness);
                gradient.pixels.setPixel32(px, py, color);
            }
        }
        gradient.pixels.unlock();
        gradient.dirty = true;

        selectedColor = getColorAt(Std.int(lastCursorX), Std.int(lastCursorY));
    }
}