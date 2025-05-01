package chartdex.format;

import chartdex.Chartdex.ChartdexLogLevel;

class Format {
	public final function new() {}

	public function getName():String {
		return 'Unknown Format';
	}

	public function createWrapper():FormatWrapper {
		Chartdex.log(ChartdexLogLevel.WARNING, 'Wrapper for ${this.getName()} not implemented, returning empty wrapper');
		return new FormatWrapper(this);
	}

	public function isMatch(path:String):Bool {
		Chartdex.log(ChartdexLogLevel.ERROR, 'Checking if ${this.getName()} matches $path not implemented');
		return false;
	}

	public function print(chart:Chart):String {
		Chartdex.log(ChartdexLogLevel.ERROR, 'Printing ${this.getName()} not implemented');
		return null;
	}
}

class FormatWrapper {
	public final format:Format;
	public var charts:Array<Chart> = [];

	public function new(format:Format) {
		this.format = format;
	}

	public function load(path:String):FormatWrapper {
		Chartdex.log(ChartdexLogLevel.WARNING, 'Loading ${format.getName()} from $path not implemented');
		return this;
	}

	public function findChart(variation:String):Chart {
		return Lambda.find(charts, chart -> chart.variation == variation);
	}

	public function hasChart(variation:String):Bool {
		return findChart(variation) != null;
	}
}
