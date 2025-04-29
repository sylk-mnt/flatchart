package flatchart.format;

class Format {
	public function new() {}

	public function getName():String {
		return 'Unknown Format';
	}

	public function createWrapper():FormatWrapper {
		return new FormatWrapper();
	}

	public function isMatch(path:String):Bool {
		return false;
	}
}

class FormatWrapper {
	public var metadata:FormatMetadata;
	public var charts:Array<FormatChart> = [];

	public function new() {}

	public function load(path:String):FormatWrapper {
		return this;
	}

	public function findChart(variation:String):FormatChart {
		return Lambda.find(charts, chart -> chart.variation == variation);
	}

	public function hasChart(variation:String):Bool {
		return Lambda.exists(charts, chart -> chart.variation == variation);
	}
}

@:structInit class FormatMetadata {
	public var title:String;
	public var artist:String;
	public var album:String;
	public var charter:String;
	public var bpmChanges:Array<FormatBpmChange>;
}

@:structInit class FormatBpmChange {
	public var time:Float;
	public var bpm:Float;
	public var beatsPerMeasure:Float;
	public var stepsPerBeat:Float;
}

@:structInit class FormatChart {
	public var variation:String;
	public var metadata:FormatMetadata;
	public var tracks:Array<FormatTrack>;
	public var strumlines:Array<FormatStrumline>;
	public var notes:Array<FormatNote>;
	public var events:Array<FormatEvent>;
	public var stage:Null<String>;
}

@:structInit class FormatTrack {
	public var sound:String;
	public var startTime:Float;
	public var endTime:Float;
}

@:structInit class FormatStrumline {
	public var x:Float;
	public var scale:Float;
	public var alpha:Float;

	public var characters:Array<String>;
	public var charactersPosition:Int;

	public var cpuControlled:Bool;
}

@:structInit class FormatNote {
	public var time:Float;
	public var sustain:Float;
	public var lane:Int;
	public var kind:String;
}

@:structInit class FormatEvent {
	public var time:Float;
	public var kind:String;
	public var data:Dynamic;
}
