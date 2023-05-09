package;

import kha.Color;
import kha.math.Vector2i;
import kha.graphics2.Graphics;
import haxe.Json;

import JsonFormat.TStage;

class Stage {
    public var name:String;
    public var size:Vector2i;
    public var windowSize:Vector2i;
    public var layers:Array<Layer>;
    public var bgColor:Color;
    public var pixelPerfect:Bool;

    var imageLayers:Array<Layer>; // flattened array of image layers
    var mouseLayers:Array<Layer>; // flattened array of clickable layers

    public var data:TStage;


    public function new(data:TStage) {
        this.data = data;
        name = data.name;
        size = new Vector2i(data.size[0], data.size[1]);
        windowSize = new Vector2i(data.window[0], data.window[1]);
        pixelPerfect = data.pixelPerfect;
        bgColor = Color.fromString(data.background);

        layers = [for (ld in data.layers) new Layer(ld)];
        sortLayers();
    }


    public static function fromString(s:String) {
        return new Stage(Json.parse(s));
    }


    function sortLayers() {
        imageLayers = [];
        mouseLayers = [];

        for (layer in layers)
            if (layer.group)
                for (gayer in layer.layers) {
                    imageLayers.push(gayer);
                    if (!gayer.locked)
                        mouseLayers.push(gayer);
                }
            else {
                imageLayers.push(layer);
                if (!layer.locked)
                    mouseLayers.push(layer);
            }

        mouseLayers.reverse();
    }


    public function pick(x:Float, y:Float,):Null<Layer> {
        for (layer in mouseLayers) {
            if (layer.image == null)
                continue;

            if (x >= layer.pos.x && x <= layer.pos.x + layer.size.x && y >= layer.pos.y
                    && y <= layer.pos.y + layer.size.y) {
                var px = layer.image.at(Std.int(x - layer.pos.x + layer.src.x), Std.int(y - layer.pos.y + layer.src.y));
                if (px.A > 0.01)
                    return layer;
            }
        }
        return null;
    }


    public function raise(layer:Layer) {
        var stack = (layer.parent != null) ? layer.parent.layers : layers;
        stack.remove(layer);
        stack.push(layer);
        sortLayers();
    }


    public function draw(g:Graphics) {
        for (layer in imageLayers)
            if (layer.image != null)
                g.drawSubImage(layer.image, layer.pos.x, layer.pos.y, layer.src.x, layer.src.y,
                        layer.size.x, layer.size.y);
    }
}