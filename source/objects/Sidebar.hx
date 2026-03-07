package objects;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import objects.Canvas;
import objects.ColorPicker;
import objects.LayerList;
import objects.ui.Button;
import objects.ui.Slider;

class Sidebar extends FlxSpriteGroup {
	public var sidebarWidth:Int = 240;
	public var sidebarPadding:Int = 20;
	public var sidebarSpacing:Int = 10;
	public var sidebarYOffset:Int = 40;

	var canvas:Canvas;
	var hudCamera:FlxCamera;

	var bg:FlxSprite;
	var bottomGroup:FlxSpriteGroup;
	var hueSlider:Slider;
	var colorPicker:ColorPicker;
	var colorPreview:FlxSprite;
	var brushSizeSlider:Slider;
	var brushSizeIndicator:FlxText;
	var sliderDiv:FlxSprite;
	var layersDiv:FlxSprite;
	var brushLabel:FlxText;
	var layersLabel:FlxText;
	var addLayerBtn:Button;

	public var layerList:LayerList;

	public function new(canvas:Canvas, hudCamera:FlxCamera) {
		super();
		this.canvas = canvas;
		this.hudCamera = hudCamera;
		this.cameras = [hudCamera];

		build();
		Theme.onThemeChanged.add(refreshColors);
	}

	function refreshColors() {
		FlxG.camera.bgColor = Theme.surface;
		bg.color = Theme.container;
		sliderDiv.color = Theme.divider;
		layersDiv.color = Theme.divider;
		brushLabel.color = Theme.onContainer;
		brushSizeIndicator.color = Theme.onContainer;
		layersLabel.color = Theme.onContainer;
		addLayerBtn.bgColorDefault = Theme.containerHigh;
		addLayerBtn.bgColorHovered = Theme.buttonHover;
		addLayerBtn.bgColorPressed = Theme.buttonPressed;
	}

	function build() {
		var fullWidth:Int = sidebarWidth - (sidebarPadding * 2);

		bg = new FlxSprite().makeGraphic(sidebarWidth, 1);
		bg.color = Theme.container;
		bg.origin.set(0.5, 0);
		add(bg);

		var yPos:Int = sidebarPadding;

		// color picker row
		var colorPickerSize:Int = fullWidth - sidebarSpacing - 20;
		colorPicker = new ColorPicker(sidebarPadding, sidebarPadding, colorPickerSize, colorPickerSize);
		colorPicker.cameras = [hudCamera];
		colorPicker.onColorChanged = (color:FlxColor) -> {
			if (canvas.focusedLayer != null)
				canvas.brushColor = colorPreview.color = color;
		};
		add(colorPicker);

		colorPreview = new FlxSprite(colorPicker.x + colorPicker.width + sidebarSpacing, colorPicker.y);
		colorPreview.cameras = [hudCamera];
		colorPreview.makeGraphic(20, colorPickerSize);
		add(colorPreview);

		yPos += Std.int(colorPickerSize + sidebarSpacing);

		// hue slider
		hueSlider = new Slider(sidebarPadding, yPos, fullWidth, 10);
		hueSlider.cameras = [hudCamera];
		hueSlider.min = 0;
		hueSlider.max = 360;
		hueSlider.stepSize = 1;
		hueSlider.value = 0;
		hueSlider.makeRainbowGradient();
		hueSlider.onChanged = (hue:Float) -> {
			colorPicker.updateGradient(hue);
			canvas.brushColor = colorPreview.color = colorPicker.selectedColor;
		};
		add(hueSlider);

		yPos += Std.int(hueSlider.height + sidebarSpacing);

		sliderDiv = new FlxSprite(sidebarPadding, yPos).makeGraphic(fullWidth, 1, Theme.divider);
		add(sliderDiv);

		yPos += Std.int(sliderDiv.height + sidebarSpacing);

		// brush size row
		brushLabel = new FlxText(sidebarPadding, yPos, -1, "Brush Size", 12);
		brushLabel.color = Theme.onContainer;
		add(brushLabel);

		brushSizeIndicator = new FlxText(fullWidth, yPos + 2, -1, '${canvas.brushSize}px', 10);
		brushSizeIndicator.x -= brushSizeIndicator.width;
		brushSizeIndicator.color = Theme.onContainer;
		brushSizeIndicator.alpha = 0.7;
		add(brushSizeIndicator);

		brushSizeSlider = new Slider(sidebarPadding, yPos + brushLabel.height, fullWidth, 10);
		brushSizeSlider.cameras = [hudCamera];
		brushSizeSlider.min = 0;
		brushSizeSlider.max = 100;
		brushSizeSlider.stepSize = 0.2;
		brushSizeSlider.value = canvas.brushSize;
		brushSizeSlider.onChanged = (value:Float) -> {
			var oldX:Float = brushSizeIndicator.x;
			brushSizeIndicator.text = '${value}px';
			var newX:Float = x + fullWidth - brushSizeIndicator.width;
			brushSizeIndicator.x += newX - oldX;
			if (canvas.focusedLayer != null)
				canvas.brushSize = value;
		};
		add(brushSizeSlider);

		yPos += Std.int(brushSizeSlider.height + brushLabel.height + sidebarSpacing);

		// layers section
		layersDiv = new FlxSprite(sidebarPadding, yPos).makeGraphic(fullWidth, 1, Theme.divider);
		add(layersDiv);

		yPos += Std.int(layersDiv.height + sidebarSpacing);

		layersLabel = new FlxText(sidebarPadding, yPos, -1, "Layers", 12);
		layersLabel.color = Theme.onContainer;
		add(layersLabel);

		yPos += Std.int(layersLabel.height + 5);

		layerList = new LayerList(sidebarPadding, yPos, fullWidth, 200, canvas);
		layerList.cameras = [hudCamera];
		layerList.rebuild();
		add(layerList);

		yPos += Std.int(layerList.height + sidebarSpacing);

		addLayerBtn = new Button(sidebarPadding, yPos, "+ Add Layer", fullWidth, 25);
		addLayerBtn.cameras = [hudCamera];
		addLayerBtn.onClick = () -> {
			canvas.addLayer(true);
			layerList.rebuild();
		};
		add(addLayerBtn);

		// bottom group (save/load/export)
		bottomGroup = new FlxSpriteGroup();
		bottomGroup.cameras = [hudCamera];

		var yPosBtm:Int = 0;

		var save = new Button(sidebarPadding, yPosBtm, "Save Project", fullWidth, 20);
		save.cameras = [hudCamera];
		save.onClick = () -> canvas.saveProject(() -> trace("Project saved!"));
		bottomGroup.add(save);

		yPosBtm += Std.int(save.height + sidebarSpacing);

		var load = new Button(sidebarPadding, yPosBtm, "Load Project", fullWidth, 20);
		load.cameras = [hudCamera];
		load.onClick = () -> canvas.loadProject(() -> {
			layerList.rebuild();
		}, (error) -> trace("Load error: " + error));
		bottomGroup.add(load);

		yPosBtm += Std.int(load.height + sidebarSpacing);

		var export = new Button(sidebarPadding, yPosBtm, "Export PNG", fullWidth, 20);
		export.cameras = [hudCamera];
		export.onClick = () -> canvas.exportToPNG(() -> trace("PNG exported!"));
		bottomGroup.add(export);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		bg.scale.y = FlxG.height - sidebarYOffset;
		y = sidebarYOffset;
		x = FlxG.width - sidebarWidth;
		bottomGroup.x = x;
		bottomGroup.y = FlxG.height - sidebarPadding - bottomGroup.height;
	}
}