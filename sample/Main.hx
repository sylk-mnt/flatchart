package sample;

import flatchart.format.LegacyFormat;
import flatchart.fs.SysFileSystem;
import flatchart.FlatChart;

function main() {
	FlatChart.init({
		onLog: (_, message) -> trace('FlatChart: $message'),
		fileSystem: new SysFileSystem(),
		formats: [new LegacyFormat()]
	});

	final wrapper = FlatChart.detectAndWrapFormat('sample/bopeebo');
	trace(wrapper.charts.length);
	trace(wrapper.charts.map(chart -> '${chart.variation} ${chart.metadata.title}'));
}
