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
	var cameraPanBtn:Button;

	function build() {
		var fullWidth:Int = toolbarWidth - (toolbarPadding * 2);

		bg = new FlxSprite().makeGraphic(toolbarWidth, 1, Colors.container);
		bg.origin.set(0.5, 0);
		add(bg);

		var yPos:Int = toolbarPadding;

		for (button in ['brush', 'eraser', 'camera_pan',]) {
			var object:Button = new Button(toolbarPadding, yPos, '', fullWidth, fullWidth, button.toLowerCase());

			object.onClick = () -> {
				PlayState.cameraPanningTool = false;
				PlayState.middleMousePanning = false;

				switch (button.toLowerCase()) {
					case 'brush':
						canvas.brushMode = DRAW;
					case 'eraser':
						canvas.brushMode = ERASE;
					case 'camera_pan':
						canvas.brushMode = NONE;
						PlayState.cameraPanningTool = true;

						PlayState.lastMouseX = FlxG.mouse.getViewPosition().x;
						PlayState.lastMouseY = FlxG.mouse.getViewPosition().y;
				}
			}

			add(object);

			yPos += Std.int(object.height + toolbarSpacing);

			switch (button.toLowerCase()) {
				case 'brush':
					brushBtn = object;
				case 'eraser':
					eraserBtn = object;
				case 'camera_pan':
					cameraPanBtn = object;
			}
		}
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		bg.scale.y = FlxG.height - toolbarYOffset;
		y = toolbarYOffset;

		brushBtn.bgColorDefault = (canvas.brushMode == DRAW) ? Colors.buttonHover : Colors.container;
		eraserBtn.bgColorDefault = (canvas.brushMode == ERASE) ? Colors.buttonHover : Colors.container;
		cameraPanBtn.bgColorDefault = (PlayState.cameraPanningTool) ? Colors.buttonHover : Colors.container;
	}
}
