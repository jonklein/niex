import '@fortawesome/fontawesome-free/js/fontawesome'
import '@fortawesome/fontawesome-free/js/solid'

import Prism from 'prismjs';

import Chartkick from "chartkick"
import ChartJS from "chart.js"

const resizeTextArea = (el) => {
    el.style.height = "5px"
    el.style.height = (el.scrollHeight) + "px"
}

export const hooks = {
    NiexChart: {
        mounted: function () {
            let data = JSON.parse(this.el.attributes['data-chart'].value)
            let f = Chartkick[data.type]
            let options = data.options || {}
            new f(this.el, data.data, options)
        },
        updated: function () {
            let data = JSON.parse(this.el.attributes['data-chart'].value)
            let f = Chartkick[data.type]
            let options = data.options || {}
            new f(this.el, data.data, options)
        }
    },

    NiexPage: {
        mounted: function () {
            window.addEventListener("click", (e) => {
                // any click not the child of a cell should blur

                if (!e.target.closest(".cell")) {
                    this.pushEvent("blur-cell", {})
                }
            })

            window.addEventListener("keypress", (e) => {
                if (e.code === "KeyS" && e.metaKey) {
                    this.pushEvent("save", {})
                    e.preventDefault()
                    e.stopPropagation()
                }

                if (e.code === "KeyO" && e.metaKey) {
                    this.pushEvent("open", {})
                    e.preventDefault()
                    e.stopPropagation()
                }
            })
        }
    },

    NiexEditor: {
        mounted: function () {
            this.el.addEventListener("input", e => resizeTextArea(e.target));
            resizeTextArea(this.el)
        },
        updated: function () {
            resizeTextArea(this.el)
        }

    },

    NiexCodeEditor: {
        mounted: function () {
            this.el.addEventListener("input", e => resizeTextArea(e.target));
            resizeTextArea(this.el)

            this.el.addEventListener("keydown", (e) => {
                if (e.metaKey && e.code === "Enter") {
                    e.target.closest(".content").querySelector("button[class='run']").click()
                }
            })
        },
        updated: function () {
            resizeTextArea(this.el)
        }
    },

    NiexOutput: {
        highlight: function (el) {
            if(el.attributes['data-type'].value == "code")
                el.innerHTML = Prism.highlight(el.innerText, Prism.languages.elixir, 'elixir');
        },
        mounted: function () {
            this.highlight(this.el)
        },
        updated: function () {
            this.highlight(this.el)
        }

    }
}