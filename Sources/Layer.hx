package;

import kha.math.Vector2;
import kha.math.Vector2i;
import kha.Image;
import JsonFormat.TLayer;
using StringTools;

import Loader;

class Layer {
    public var name:String;
    public var group = false;
    public var parent:Layer;
    public var copy = false;

    public var image:Image = null;
    public var pos = new Vector2();
    public var src = new Vector2i();
    public var size = new Vector2i();
    public var locked = true;

    public var layers:Array<Layer> = null;

    public var data:TLayer;


    public function new(data:TLayer, ?parent=null) {
        this.data = data;
        this.parent = parent;
        name = data.name;
        group = data.group;

        if (group) {
            layers = [for (ld in data.layers) new Layer(ld, this)];
        } else {
            Loader.loadImage(data.image, img -> image = img);
            pos.x = data.pos[0];
            pos.y = data.pos[1];
            src.x = data.src[0];
            src.y = data.src[1];
            size.x = data.size[0];
            size.y = data.size[1];
            locked = data.locked;
        }
    }
}