# Niex

Niex is an interactive Elixir code notebook built with Phoenix LiveView.

![An animation of a Niex notebook  in action](https://github.com/jonklein/niex/blob/master/sample_notebooks/demo.gif?raw=true)


## Getting Started

There are two main ways to run Niex: as a standalone Phoenix app, or embedded as a dependency in your own code base. 

### Running standalone

If you're looking to get started quickly with Niex, you can clone the Niex repo from GitHub and run as a simple 
Phoenix app:

```
git clone https://github.com/jonklein/niex.git
cd niex
mix phx.server
```

Then open `http://localhost:4000` to use the notebook.

### Embedding in your project

If you'd like to use Niex in your own Elixir project, and use your own code in notebooks, you can install Niex as a 
dependency:

```

```

### Why Niex?

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

## Notebook format

Notebooks are stored in a JSON format generally inspired by the Jupyter notebook format, but greatly simplified.  

Sample notebook:

```
{
  "version": "1.0",
  "metadata": { "name": "New Notebook" },
  "worksheets": {
  } 
}

```

## Security warning - arbitrary code execution

This software enables arbitrary code execution *by design* 

