# Niex - Interactive Elixir Code Notebooks

Niex is an interactive Elixir code notebook with support for embedded media and 
charting, built with Phoenix LiveView.  Niex stores your data & code in persistent, interactive notebooks, making it great for scientific and 
data analysis applications using Elixir, or for sharing visual, interactive demos and documentation of code
written in Elixir. 

![An animation of a Niex notebook  in action](https://github.com/jonklein/niex/blob/master/sample_notebooks/demo.gif?raw=true)

Niex is inspired by the powerful and full-featured [Jupyter](https://jupyter.org/) project. You may note that Jupyter 
(with some effort) can already support Elixir as a backend, so what's the advantage of using 
Niex?  The main advantage is that Niex is simple, lightweight and written fully in Elixir, so it's easy to use as a simple 
dependency to integrate with your existing Elixir code.  It can be run as a standalone
Phoenix app, or embedded in your own Elixir project. 

## Getting Started

There are two main ways to run Niex: as a standalone Phoenix app, or embedded as a dependency in your own code base. 

### Running Niex standalone server

If you're looking to get started quickly with Niex, you can clone the Niex repo from GitHub and run as a simple 
Phoenix app:

```
git clone https://github.com/jonklein/niex.git
cd niex
mix deps.get
(cd assets; yarn)
mix phx.server
```

Then open `http://localhost:4000` to use the notebook.

### Embedding Niex in your own Elixir project

If you'd like to use Niex in your own Elixir project, and use your own codebase in your notebooks, you can install 
Niex as a dependency:

```
  defp deps do
    [
       {:niex, git: "https://github.com/jonklein/niex"}
    ]
  end
```

You will then need to configure Niex in your `config.exs` with a minimal Phoenix configuration:

```
config :phoenix, :json_library, Poison

# Configures the endpoint
config :niex, NiexWeb.Endpoint,
  pubsub_server: Niex.PubSub,
  live_view: [signing_salt: "xxxxxxxxxxxx"],
  secret_key_base: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  server: true,
  debug_errors: true,
  check_origin: false,
  http: [port: 3333],
  debug_errors: true,
  check_origin: false
```

Note: Though Niex uses Phoenix and LiveView, it runs as its own server on its own port and can be run happily alongside
your own Phoenix app.  Configure the Niex port number accordingly to avoid conflicts with the rest of your 
project - in the example above, we use port 3333. 

### Basic Usage

Niex notebooks support two types of cells: code and markdown.

Markdown cells are used for human-readable text using the [Markdown format](https://www.markdownguide.org/basic-syntax/).

Code cells are used to store & execute Elixir code.  To use a code cell, simply populate the cell and execute it using 
the "run" button (or the key combo command-retrun).  The cell output field will display the result of the execution.  
Cells must be explicity executed - if you make changes to code that other cells are dependent on, you must explicitly 
rerun those cell commands in order.   

#### Notebook & Interpreter State

Like running an IEx session, Niex maintains an internal interpreter state that is **independent of the order
of commands in the notebook**, and **is not saved in the notebook**.  This means that when you open a saved 
notebook, you must execute each cell in order to restore internal state.  

#### Asynchronous execution & animation

You can also display intermediate results for long-running code in cells.  This allows you
to create animations or updates for asynchronous processes.  To render an intermediate result
before the cell execution is complete, use `Niex.Render/1` with the content.

In this example, we render an animated sine-wave chart:

```
for j <- (1..300) do
  Process.sleep(30)
  data = (1..50) |> Enum.map(fn i -> [i, :math.sin(i / 3.0 + j / 10.0)] end)
  Niex.render(Niex.Content.chart("LineChart", data, %{points: false}))
end

"Click run to animate"
``` 

### Cell Output Display & Media

By default, Niex displays the "inspect" string of any output.  This is most useful
for looking at raw Elixir data including complex data like maps, lists & structs.

You can also control the display of output with `Niex.Content` functions.  Niex supports 
HTML, preformatted text, images, video and chart content in notebooks:

```
# Render HTML
Niex.Content.html("<h1>Hello, World</h1>")

# Render preformatted text
Niex.Content.pre("# This is a code comment")

# Render an image
image_url = "https://placekitten.com/408/287"
Niex.Content.image(image_url)

# Render a video
video_url = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
Niex.Content.video(video_url)

# Render a line chart: 
data = (1..30) |> Enum.map(fn i -> [i, :math.sin(i)] end)
Niex.Content.chart("LineChart", data, height: 400)

# Render a pie chart: 
data = %{"Elixir" => 80, "JavaScript" => 10, "Ruby" => 20}
Niex.Content.chart("PieChart", data, height: 400)
```

Niex uses the [Chartkick](https://chartkick.com) library for charting, and many other 
chart types are available.  See the [Chartkick JavaScript documentation](https://github.com/ankane/chartkick.js) for 
a full list.

### Notebook format

Notebooks are stored in a JSON format generally inspired by the Jupyter notebook format, but greatly simplified.  

Sample notebook:

```
{
  "metadata": { "name": "New Notebook", "version": "1.0" },
  "worksheets": {
    "cells": [
      %{
        "cell_type": "markdown",
        "content": ["# Welcome to Niex"]
      }, %{
        "cell_type": "code",
        "content": ["IO.inspect(\"123\")"],
        "output": [{"text" => 123}]
      }
    ],
  } 
}

```

## Known issues / future improvements 

- executed code is **not** sandboxed - see section below on arbitrary code execution
- future work - add support for other media types
- notebook format & details are subject to change

## WARNING: arbitrary code execution

This software enables arbitrary code execution **by design** – it is intended for **development and local use only**.  If you
choose to expose any Niex functionality over a network, you are responsible for
implementing the necessary authorization and access controls. 

