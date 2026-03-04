// source/objects/Canvas.hx (updated)
package objects;

import backend.Colors;
import backend.ProjectHandler;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;

/**
 * Canvas is an object containing bunch of layers.
 */
class Canvas extends FlxSpriteGroup {
    public var layers:Array<Layer> = [];
    public var focusedLayer:Layer;
    
    public var projectName:String = "Untitled";
    public var projectFilePath:String;
    
    var borderThickness:Int = 1;
    public var canvasWidth:Int = 0;
    public var canvasHeight:Int = 0;
    
    public var brushColor:FlxColor = FlxColor.WHITE;
    public var brushSize:Float = 3;
    public var brushMode:BrushMode = DRAW;
    
    var background:FlxSprite;
    var backgroundCheckerLight:FlxColor = Colors.canvasCheckerLight;
    var backgroundCheckerDark:FlxColor = Colors.canvasCheckerDark;
    var border:FlxSprite;
    var layerGroup:FlxSpriteGroup;

    /**
     * Create a new canvas.
     * @param width Canvas' width.
     * @param height Canvas' height.
     */
    public function new(width:Int, height:Int) {
        super();
        canvasWidth = width;
        canvasHeight = height;
        
        _initBackground();
        _initBorder();
        
        layerGroup = new FlxSpriteGroup();
        layerGroup.setPosition(borderThickness, borderThickness);
        add(layerGroup);
    }

    /**
     * Add a new layer.
     * @param focus Automatically focus to this layer.
     * @return Layer Newly created layer.
     */
    public function addLayer(focus:Bool = false):Layer {
        var layer:Layer = new Layer(canvasWidth, canvasHeight, this);
        layerGroup.insert(0, layer);
        layers.push(layer);

        if (focus)
            setFocus(layer.layerID);

        return layer;
    }

    /**
     * Set current focused layer.
     * @param layerID Layer ID to focus.
     */
    public function setFocus(layerID:Int) {
        for (layer in layers) {
            layer.isFocused = false;
            layer.active = true;
        }
        for (layer in layers) {
            if (layer.layerID == layerID) {
                layer.isFocused = true;
                focusedLayer = layer;
                return;
            }
        }
    }
    
    /**
     * Set layer visibility.
     * @param layerID Layer ID to modify.
     * @param visible Visibility state.
     */
    public function setLayerVisibility(layerID:Int, visible:Bool) {
        for (l in layers) {
            if (l.layerID == layerID) {
                l.visible = visible;
                return;
            }
        }
    }

    /**
     * Remove a layer from the canvas.
     * @param layerID Layer ID to remove.
     * @return Bool Whether the layer was removed (false if it's the last layer).
     */
    public function removeLayer(layerID:Int):Bool {
        if (layers.length <= 1) return false;
        
        for (l in layers) {
            if (l.layerID == layerID) {
                layers.remove(l);
                layerGroup.remove(l);
                l.destroy();
                
                if (focusedLayer != null && focusedLayer.layerID == layerID)
                    setFocus(layers[0].layerID);
                
                return true;
            }
        }
        
        return false;
    }

    /**
     * Remove all layers from the canvas.
     */
    public function removeAllLayers() {
        for (l in layers) {
            layers.remove(l);
            layerGroup.remove(l);
            l.destroy();
        }

        layerGroup.clear();
        layers = [];
    }

    /**
     * Move a layer up or down.
     * @param layerID   Layer ID to move.
     * @param direction -1 = move up (rendered on top), 1 = move down (rendered below).
     * @return Bool Whether the move was performed.
     */
    public function reorderLayer(layerID:Int, direction:Int):Bool {
        var idx:Int = -1;
        for (i in 0...layers.length) {
            if (layers[i].layerID == layerID) {
                idx = i;
                break;
            }
        }
        if (idx == -1) return false;

        var newIdx:Int = idx + direction;
        if (newIdx < 0 || newIdx >= layers.length) return false;

        var tmp:Layer = layers[idx];
        layers[idx] = layers[newIdx];
        layers[newIdx] = tmp;

        while (layerGroup.members.length != 0) {
            layerGroup.members.remove(layerGroup.members[0]);
        }

        for (i in 0...layers.length) {
            var renderIdx:Int = layers.length - 1 - i;
            layers[i].setPosition();
            layerGroup.insert(renderIdx, layers[i]);
        }

        return true;
    }

    public function getLayerPixels(layerID:Int) {
        for (l in layers) {
            if (l.layerID == layerID) {
                return l.pixels;
            }
        }
        return null;
    }

    /**
     * Export canvas to PNG
     */
    public function exportToPNG(?onComplete:Void->Void) {
        ProjectHandler.exportToPNG(this, onComplete);
    }

    /**
     * Save project
     */
    public function saveProject(?onComplete:Void->Void) {
        ProjectHandler.save(this, onComplete);
    }

    /**
     * Save project as a different file
     */
    public function saveProjectAs(?onComplete:Void->Void) {
        ProjectHandler.saveAs(this, onComplete);
    }

    /**
     * Load project
     */
    public function loadProject(?onComplete:Void->Void, ?onError:String->Void) {
        ProjectHandler.load(this, onComplete, onError);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
    }  

    function _initBorder() {
        border = new FlxSprite();
        border.makeGraphic(
            canvasWidth + (borderThickness * 2), 
            canvasHeight + (borderThickness * 2), 
            FlxColor.TRANSPARENT
        );
        
        FlxSpriteUtil.drawRect(
            border,
            0, 0,
            border.width,
            border.height,
            FlxColor.TRANSPARENT,
            { thickness: borderThickness, color: Colors.border }
        );
        add(border);
    }

    function _initBackground() {
        background = FlxGridOverlay.create(
            20,
            20,
            canvasWidth, 
            canvasHeight, 
            true,
            backgroundCheckerLight,
            backgroundCheckerDark
        );
        background.setPosition(borderThickness, borderThickness);
        add(background);
    }
}

enum BrushMode {
    DRAW;
    ERASE;
	NONE;
}