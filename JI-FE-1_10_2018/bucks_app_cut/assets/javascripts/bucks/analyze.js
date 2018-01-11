window.onload = function() {
	if (typeof nv !== 'undefined') {
	nv.addGraph(function() {
		var issuedPieChart = nv.models.pieChart()
		.x(function(d) { return d.label })
		.y(function(d) { return d.value * 100.0 })
		.showLabels(false)
		.showLegend(false);

		d3.select("#issued_pie_chart")
		.datum(issuedData())
		.transition().duration(350)
		.call(issuedPieChart);

		d3.select("#issued_pie_chart")
			.append("text")
		  .attr("x", 300)             
		  .attr("y", 30)
		  .attr("text-anchor", "middle")  
		  .text("Issued");

		return issuedPieChart;
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
		var earnedPieChart = nv.models.pieChart()
		.x(function(d) { return d.label })
		.y(function(d) { return d.value  * 100.0 })
		.showLabels(false)
		.showLegend(false);

		d3.select("#earned_pie_chart")
		.datum(earnedData())
		.transition().duration(350)
		.call(earnedPieChart);
		
		d3.select("#earned_pie_chart")
			.append("text")
		  .attr("x", 300)             
		  .attr("y", 30)
		  .attr("text-anchor", "middle")  
		  .text("Earned");

		return earnedPieChart;
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
	  var issuedMonthlineChart = nv.models.lineChart()
	                .margin({left: 75})  //Adjust chart margins to give the x-axis some breathing room.
	                .useInteractiveGuideline(true)  //We want nice looking tooltips and a guideline!
	                .transitionDuration(350)  //how fast do you want the lines to transition?
	                .showLegend(true)       //Show the legend, allowing users to turn on/off line series.
	                .showYAxis(true)        //Show the y-axis
	                .showXAxis(true)        //Show the x-axis
	  ;

	  issuedMonthlineChart.xAxis     //Chart x-axis settings
	      .axisLabel('Day');

	  issuedMonthlineChart.yAxis     //Chart y-axis settings
	      .axisLabel('Issued');

	  /* Done setting the chart up? Time to render it!*/
	  var myData = issuedLineData();   //You need data...

	  d3.select('#budget_line_graph')    //Select the <svg> element you want to render the chart in.   
	      .datum(myData)         //Populate the <svg> element with chart data...
	      .call(issuedMonthlineChart);          //Finally, render the chart!

	  //Update the chart when window resizes.
	  nv.utils.windowResize(function() { issuedMonthlineChart.update() });

	  return issuedMonthlineChart;
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



