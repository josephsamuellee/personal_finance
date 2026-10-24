import { Controller } from "@hotwired/stimulus"
import * as echarts from "echarts"

export default class extends Controller {
  static values = {
    points: Array,
    mode: { type: String, default: "net-worth" }
  }

  connect() {
    this.chart = echarts.init(this.element)
    this.render()
    this.observer = new MutationObserver(() => this.render())
    this.observer.observe(document.documentElement, { attributes: true, attributeFilter: ["class", "data-appearance"] })
    this.onResize = () => window.requestAnimationFrame(() => this.chart?.resize())
    window.addEventListener("resize", this.onResize)
  }

  disconnect() {
    this.observer?.disconnect()
    window.removeEventListener("resize", this.onResize)
    this.chart?.dispose()
  }

  render() {
    const text = getComputedStyle(document.body).color
    const bar = this.paint("--chart-bar")
    const line = this.paint("--chart-line")
    const axis = this.paint("--chart-axis")
    this.element.dataset.chartTextColor = text
    this.element.dataset.chartBarColor = bar
    this.element.dataset.chartLineColor = line
    const axisStyle = { axisLabel: { color: axis }, axisLine: { lineStyle: { color: axis } } }
    if (this.modeValue === "spending") {
      this.chart.setOption({
        textStyle: { color: text },
        tooltip: { trigger: "axis" },
        xAxis: { type: "time", ...axisStyle },
        yAxis: [
          { type: "value", name: "Cumulative", position: "left", axisLabel: { color: axis }, splitLine: { lineStyle: { color: axis } } },
          { type: "value", name: "Daily", position: "right", axisLabel: { color: axis }, splitLine: { show: false } }
        ],
        series: [
          {
            name: "Cumulative",
            type: "line",
            yAxisIndex: 0,
            data: this.pointsValue.map((point) => [point.date, Number(point.cumulative)]),
            lineStyle: { color: line },
            itemStyle: { color: line }
          },
          {
            name: "Daily",
            type: "bar",
            yAxisIndex: 1,
            data: this.pointsValue.map((point) => [point.date, Number(point.amount)]),
            itemStyle: { color: bar }
          }
        ]
      }, true)
    } else {
      this.chart.setOption({
        textStyle: { color: text },
        tooltip: { trigger: "axis" },
        xAxis: { type: "time", ...axisStyle },
        yAxis: {
          type: "value",
          scale: true,
          axisLabel: { color: axis },
          splitLine: { lineStyle: { color: axis } }
        },
        series: [{
          type: "line",
          data: this.pointsValue.map((point) => [point.date, Number(point.amount)]),
          lineStyle: { color: line },
          itemStyle: { color: line }
        }]
      }, true)
    }
  }

  paint(property) {
    const probe = document.createElement("span")
    probe.style.color = `var(${property})`
    this.element.appendChild(probe)
    const color = getComputedStyle(probe).color
    probe.remove()
    return color
  }
}
