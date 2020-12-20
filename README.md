# Niex - Interactive Elixir Code Notebooks

Niex is an interactive Elixir code notebook built with Phoenix LiveView with support for embedded media and 
charting.  Niex stores your data & code in persistent, interactive notebooks, making it  great for scientific and data analysis applications using Elixir, or for sharing interactive demos of your Elixir code. 

![An animation of a Niex notebook  in action](https://github.com/jonklein/niex/blob/master/sample_notebooks/demo.gif?raw=true)

## Why Niex?

You may note that the powerful, full-featured [Jupyter](https://jupyter.org/) project is already capable of supporting other language backends, 
including Elixir, so what's the advantage of using Niex for an interactive Elixir notebook?

- Embeddable - Niex is easily embedable in your own Elixir project so that you can easily use it 
as a development and exploration workspace for your own code.   

- Simple - Niex offers a simple Phoenix/Elixir app to get up and running quickly & easily or to deploy however you prefer to 
deploy your Phoenix apps. 

- Lightweight

Niex is extremely lightweight

- Written in native Elixir, so it integrates easily with your existing Elixir project and lets you use your own code 
in notebooks

## Getting Started

There are two main ways to run Niex: as a standalone Phoenix app, or embedded as a dependency in your own code base. 

### Running Niex standalone server

If you're looking to get started quickly with Niex, you can clone the Niex repo from GitHub and run as a simple 
Phoenix app:

```
git clone https://github.com/jonklein/niex.git
cd niex
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
  live_view: [signing_salt: "xxxxxxxxx"],
  secret_key_base: "xxxxxxxxxx",
  server: true,
  debug_errors: true,
  check_origin: false,
  http: [port: 3333],
  debug_errors: true,
  check_origin: false
```

Note: Though Niex uses Phoenix and LiveView, it runs as its own server on its own port and can be run happily alongside
your own Phoenix app. 

### Media

Niex supports embeddable image, video and chart content in notebooks:

```
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

- executed code is *not* sandboxed - see section below on arbitrary code execution
- `alias`, `import` and `use` do not function as expected in the notebook
- future work - add support for other media types
- future work - add support custom Live components in cells

## Warning - arbitrary code execution

This software enables arbitrary code execution *by design* – is for *development and local use only*.  If you
choose expose any Niex functionality is available over a network, you are responsible for
implementing the necessary authorization and access controls. 

