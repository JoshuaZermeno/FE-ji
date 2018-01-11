// One of the few js files that I have left that I havn't converted to CoffeeScript and
// havn't flooded with jQuery.
// Takes data populated by a lot of careful SQL queries, populates a hidden table on 
// the webpage, reads though the table with basic parsing, and feeds the data into the
// nv charts built on d3.js.
//
// Future plans were to send raw JSON data to an HTML tag, then retrieve and parse as usual,
// but this did the trick for the time being..

window.onload = function() {
	if (typeof nv !== 'undefined') {
	nv.addGraph(function() {
		var chart = nv.models.pieChart()
		.x(function(d) { return d.label })
		.y(function(d) { return d.value * 100.0 })
		.showLabels(false)
		.showLegend(false);

		d3.select("#issued_pie_chart")
		.datum(issuedData())
		.transition().duration(350)
		.call(chart);

		d3.select("#issued_pie_chart")
			.append("text")
		  .attr("x", 300)             
		  .attr("y", 30)
		  .attr("text-anchor", "middle")  
		  .text("Issued");

		return chart;
	});

	function issuedData() {
		var data = [];
		var table = document.getElementById('issued_data_table');
		var total = 0;

		if (table != undefined) {
			for (i=1; i < table.rows.length; i++) {
			total += parseInt(table.rows[i].cells[3].innerHTML);
			}
			for (i=1; i < table.rows.length; i++) {
				data.push({ 'label' : table.rows[i].cells[1].innerHTML,'value' : (parseInt(table.rows[i].cells[3].innerHTML) / total)});
			}
		}
		return data;
	}

	nv.addGraph(function() {
		var chart = nv.models.pieChart()
		.x(function(d) { return d.label })
		.y(function(d) { return d.value  * 100.0 })
		.showLabels(false)
		.showLegend(false);

		d3.select("#earned_pie_chart")
		.datum(earnedData())
		.transition().duration(350)
		.call(chart);
		
		d3.select("#earned_pie_chart")
			.append("text")
		  .attr("x", 300)             
		  .attr("y", 30)
		  .attr("text-anchor", "middle")  
		  .text("Earned");

		return chart;
	});

	function earnedData() {
		var data = [];
		var table = document.getElementById('earned_data_table');
		var total = 0;

		if (table != undefined) {
			for (i=1; i < table.rows.length; i++) {
			total += parseInt(table.rows[i].cells[3].innerHTML);
			}
			for (i=1; i < table.rows.length; i++) {
				data.push({ 'label' : table.rows[i].cells[1].innerHTML,'value' : (parseInt(table.rows[i].cells[3].innerHTML) / total)});
			}
		}

		return data;
	}

	nv.addGraph(function() {
	  var chart = nv.models.lineChart()
      .margin({left: 75})
      .useInteractiveGuideline(true) 
      .transitionDuration(350)
      .showLegend(true)
      .showYAxis(true)
      .showXAxis(true)
	  ;

	  chart.xAxis
	      .axisLabel('Day');

	  chart.yAxis
	      .axisLabel('Issued');

	  d3.select('#budget_line_graph') 
	      .datum(issuedLineData())
	      .call(chart);

	  nv.utils.windowResize(function() { chart.update() });

	  return chart;
	});

	function issuedLineData() {
		document.getElementById('bucks_graph_data').style.display = 'none';
		var data = new Array(31);
		var table = document.getElementById('bucks_graph_data');
		var total = 0;

		for (i=0; i < table.rows.length; i++) {
			day = parseInt(table.rows[i].cells[0].innerHTML);
			data[day] = { x: day, y: parseInt(table.rows[i].cells[1].innerHTML) };
		}

		for (var j=0; j < data.length; j++) {
			if (data[j] == undefined)
				data[j] = { x: j, y: 0 };
		}

		return [{ values: data, key: 'Issued', color: '#6c4388' }];
	}

	}
};



