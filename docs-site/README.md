# Documentation Site (MkDocs + Material)

## Local preview
From repo root:

```bash
python -m pip install -r docs-site/requirements.txt
mkdocs serve -f docs-site/mkdocs.yml
```

Then open http://127.0.0.1:8000

## Deploy
Deployment is handled by `.github/workflows/docs.yml` to the `gh-pages` branch.
