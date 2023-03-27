import $ from 'jquery'
import * as d3 from 'd3' // @todo we don't need to import the entire d3 library, we can import only the parts that we use. Let's do that after the visualization is finished

$(document).ready(loadCharts)

function loadCharts () {
  d3.selectAll('.analytics-chart-container')
    .each(loadChart)
}

function loadChart () {
  const url = this.dataset.url
  d3.json(url)
    .then(parseData)
    .then((parsedData) => drawChart(d3.select(this), parsedData))
    .catch(() => { })
}

function parseData (data) {
  const parseDate = d3.timeParse('%Y-%m-%d')
  data.forEach((row) => { row[0] = parseDate(row[0]) })
  return Promise.resolve(data)
}

function drawChart (selection, data) {
  const margin = { top: 2, right: 25, bottom: 20, left: 25 }
  const width = 350
  const height = 80

  var formatDate = d3.timeFormat('%B %d, %Y')
  const [firstDate] = data[0]
  const [,, lastTotal] = data[data.length - 1]

  const x = d3.scaleTime()
    .domain(d3.extent(data, d => d[0]))
    .range([margin.left, width - margin.right])

  const y = d3.scaleLinear()
    .domain(d3.extent(data, d => d[2]))
    .range([height - margin.bottom, margin.top])

  const xAxis = d3.axisBottom(x)
    .ticks(5)
    .tickSizeOuter(0)
    .tickSizeInner(4)
    .tickFormat(multiFormat)

  const line = d3.line()
    .x(d => x(d[0]))
    .y(d => y(d[2]))

  const info = selection
    .append('div')
    .attr('class', 'analytics--info')

  const viewCounts = info
    .append('span')
    .attr('class', 'counts')
    .text(`${lastTotal} views`)

  const viewDate = info
    .append('span')
    .attr('class', 'date')
    .text(` since ${formatDate(firstDate)}`)

  const svg = selection
    .append('svg')
    .attr('class', 'analytics--chart')
    .attr('viewBox', [0, 0, width, height])
  // Uncomment below for fixed-size. Comment out for responsive size
  // .attr('width', width)
  // .attr('height', height)

  svg.append('g')
    .attr('class', 'axis axis--x')
    .attr('transform', `translate(0,${height - margin.bottom + 2})`)
    .call(xAxis)
    .call(g => hideOverflowingTickLabels(svg, g.selectAll('.tick text')))

  const chartGroup = svg.append('g')
    .attr('class', 'chart')

  const pointMarkerBar = chartGroup.append('line')
    .attr('class', 'point-marker-bar')
    .attr('y1', margin.top)
    .attr('y2', height - margin.bottom)
    .attr('display', 'none')

  chartGroup.append('path')
    .datum(data)
    .attr('class', 'line')
    .attr('d', line)

  const pointMarker = chartGroup
    .append('circle')
    .attr('class', 'point-marker')
    .attr('r', 2)
    .attr('display', 'none')

  // Interactivity

  // Binary search function to look up closet data point to a given date
  const bisectDate = d3.bisector(row => row[0])

  svg.on('mousemove click touchmove', (event) => {
    const mouseCoords = d3.pointer(event)
    const mouseDate = x.invert(mouseCoords[0])
    const [nearestDate,, nearestValue] = findNearestDataPoint(bisectDate, data, mouseDate)

    viewCounts.text(`${nearestValue} views`)
    viewDate.text(` by ${formatDate(nearestDate)}`)

    pointMarker
      .attr('display', null)
      .attr('cx', x(nearestDate))
      .attr('cy', y(nearestValue))

    pointMarkerBar
      .attr('display', null)
      .attr('x1', x(nearestDate))
      .attr('x2', x(nearestDate))
  })

  svg.on('mouseleave', event => {
    viewCounts.text(`${lastTotal} views`)
    viewDate.text(` since ${formatDate(firstDate)}`)
    pointMarker.attr('display', 'none')
    pointMarkerBar.attr('display', 'none')
  })
}

function findNearestDataPoint (bisector, data, date) {
  const i = bisector.left(data, date, 1, data.length - 1)
  const a = data[i - 1]
  const b = data[i]
  return date - a[0] > b[0] - date ? b : a
}

function hideOverflowingTickLabels (svg, tickTextSelection) {
  const svgBounds = svg.node().getBoundingClientRect()
  const svgLeft = svgBounds.x
  const svgRight = svgBounds.x + svgBounds.width

  tickTextSelection
    .filter(function () {
      // Note in d3, `this` is set to the element that we're filtering
      const tickBounds = this.getBoundingClientRect()
      const tickLeft = tickBounds.x
      const tickRight = tickBounds.x + tickBounds.width

      return (tickLeft < svgLeft || svgRight < tickRight)
    })
    .style('visibility', 'hidden')
}

/**
 * Custom multi-format override for the x-axis (time/date) tick labels.
 *
 * This is used to fix some rendering issues encountered when using the default tick formatter.
 *
 * Based on example from https://github.com/d3/d3-time-format#d3-time-format
 * @param {Date} date
 * @returns {String} Formatted string representation of the date
 */
export default function multiFormat (date) {
  const formatMillisecond = d3.timeFormat('.%L')
  const formatSecond = d3.timeFormat(':%S')
  const formatMinute = d3.timeFormat('%I:%M')
  const formatHour = d3.timeFormat('%I %p')
  const formatDay = d3.timeFormat('%a %d')
  const formatWeek = d3.timeFormat('%b %d')
  const formatMonth = d3.timeFormat('%b')
  const formatYear = d3.timeFormat('%Y')

  return (d3.timeSecond(date) < date ? formatMillisecond
    : d3.timeMinute(date) < date ? formatSecond
    : d3.timeHour(date) < date ? formatMinute
    : d3.timeDay(date) < date ? formatHour
    : d3.timeMonth(date) < date ? (d3.timeWeek(date) < date ? formatDay : formatWeek)
    : d3.timeYear(date) < date ? formatMonth
    : formatYear)(date)
}
