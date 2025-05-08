package chartdex;

@:structInit class Chart {
	public var metadata:ChartMetadata;
	public var tracks:Array<ChartTrack>;
	public var strumlines:Array<ChartStrumline>;
	public var notes:Array<ChartNote>;
	public var events:Array<ChartEvent>;
	public var stage:Null<String>;
	public var extraValues:Map<String, Dynamic>;
}

@:structInit class ChartMetadata {
	public var title:String;
	public var artist:String;
	public var album:String;
	public var charter:String;
	public var bpmChanges:Array<ChartBPMChange>;
}

@:structInit class ChartBPMChange {
	public var time:Float;
	public var bpm:Float;
	public var beatsPerMeasure:Float;
	public var stepsPerBeat:Float;

	/**
	 * Returns the crochet in milliseconds
	 */
	public function getCrochet():Float {
		return 60 / bpm * 1000;
	}

	/**
	 * Returns the step crochet in milliseconds
	 */
	public function getStepCrochet():Float {
		return getCrochet() / stepsPerBeat;
	}

	/**
	 * Returns the measure crochet in milliseconds
	 */
	public function getMeasureCrochet():Float {
		return getCrochet() * beatsPerMeasure;
	}
}

@:structInit class ChartTrack {
	public var sound:String;
	public var startTime:Float;
	public var endTime:Float;
}

@:structInit class ChartStrumline {
	public var position:Array<Float>;
	public var scale:Float;
	public var alpha:Float;

	public var noteSpeed:Float;
	public var noteDirection:Float;

	public var characters:Array<String>;
	public var charactersPosition:Int;

	public var track:Int;
	public var cpuControlled:Bool;
}

@:structInit class ChartNote {
	public var time:Float;
	public var length:Float;
	public var kind:Null<String>;
	public var lane:Int;
}

@:structInit class ChartEvent {
	public var time:Float;
	public var kind:String;
	public var data:Dynamic;
}
