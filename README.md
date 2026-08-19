# Engineering Guides

In-depth technical learning notes and reference guides for cloud-native and platform-engineering projects I work with. Each guide is a self-contained deep-dive: architecture, components, APIs, design patterns, and the surrounding ecosystem — written to be read top-to-bottom or used as a lookup reference.

Each guide is written in Markdown (with Mermaid diagrams) and also published as a browsable, printable web page.

## Guides

| Project | What it covers | Read |
|---|---|---|
| [Models as a Service](./models-as-a-service/) | Kubernetes-native control plane for governed, multi-tenant LLM inference on OpenShift (Gateway API, Kuadrant, KServe). | [Guide](./models-as-a-service/README.md) · [Web](https://chaitanya1731.github.io/guides/models-as-a-service/) |

*(More guides are added over time, one directory per project.)*

## How this repo is organised

```
guides/
├── build.sh                 # regenerates each guide's printable index.html from its README.md
├── index.html               # landing page
├── <project>/
│   ├── README.md            # the guide (source of truth; renders with diagrams on GitHub)
│   └── index.html           # generated printable / web version
└── ...
```

## Building the web pages

The Markdown files are the source of truth. To (re)generate the printable HTML pages:

```bash
./build.sh                    # rebuild every guide
./build.sh models-as-a-service # rebuild one guide
```

The generated `index.html` files are self-contained (Mermaid + Markdown rendering via CDN) and include print styles — open one in a browser and use **Print → Save as PDF** for an offline copy.

## Reading offline

- Browse any `README.md` directly on GitHub — Mermaid diagrams render inline.
- Or open a project's `index.html` locally and print to PDF.
