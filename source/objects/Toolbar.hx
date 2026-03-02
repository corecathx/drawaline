package objects;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import objects.Canvas;
import objects.ui.Button;

class Toolbar extends FlxSpriteGroup {
    public var toolbarWidth:Int = 46;
    public var toolbarPadding:Int = 6;
    public var toolbarSpacing:Int = 10;
    public var toolbarYOffset:Int = 40;

    var canvas:Canvas;
    var hudCamera:FlxCamera;

    var bg:FlxSprite;
    public function new(canvas:Canvas, hudCamera:FlxCamera) {
        super();
        this.canvas = canvas;
        this.hudCamera = hudCamera;
        this.cameras = [hudCamera];

        build();
    }

    var brushBtn:Button;
    var eraserBtn:Button;
    function build() {
        var fullWidth:Int = toolbarWidth - (toolbarPadding * 2);

        bg = new FlxSprite().makeGraphic(toolbarWidth, 1, Colors.container);
        bg.origin.set(0.5, 0);
        add(bg);

        var yPos:Int = toolbarPadding;

        // TODO: make tool list dynamic instead of hardcoded.
        brushBtn = new Button(toolbarPadding, yPos, "", fullWidth, fullWidth, 'brush');
        brushBtn.onClick = () -> {
            canvas.brushMode = DRAW;
        }
        add(brushBtn);

        yPos += Std.int(brushBtn.height + toolbarSpacing);

        eraserBtn = new Button(toolbarPadding, yPos, "", fullWidth, fullWidth, 'eraser');
        eraserBtn.onClick = () -> {
            canvas.brushMode = ERASE;
        }
        add(eraserBtn);
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        bg.scale.y = FlxG.height - toolbarYOffset;
        y = toolbarYOffset;

        switch (canvas.brushMode) {
            case DRAW: 
                brushBtn.bgColorDefault = Colors.buttonHover;
                eraserBtn.bgColorDefault = Colors.container;
            case ERASE: 
                brushBtn.bgColorDefault = Colors.container;
                eraserBtn.bgColorDefault = Colors.buttonHover;
        }
    }
}