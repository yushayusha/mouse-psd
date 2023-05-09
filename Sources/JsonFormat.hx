package;

typedef TLayer = {
	name: String,
	group: Bool,
	// specific to layer
	?image: String,
	?pos: Array<Int>,
	?src: Array<Int>,
	?size: Array<Int>,
	?locked: Bool,
	// specific to groups
	?layers: Array<TLayer>
};


typedef TStage = {
	name:String,
	size:Array<Int>,
	window:Array<Int>,
	background:String,
	pixelPerfect:Bool,
	bgm:String,
	sfx:String,
	layers:Array<TLayer>
};