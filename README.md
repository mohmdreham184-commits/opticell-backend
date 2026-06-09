# Opticell Backend

This backend provides:

- `GET /api/reports` - fetch current reports
- `GET /api/reports/stream` - live SSE feed for report updates
- `POST /api/reports` - add a new report

## Environment

Set the following environment variable:

- `MONGODB_URI` - MongoDB connection string for your reports database.

Example:

```env
MONGODB_URI=mongodb+srv://USERNAME:PASSWORD@opticell.cwxvi7c.mongodb.net/?appName=opticell
```

## Deployment

A GitHub Actions workflow is already present at `.github/workflows/deploy-railway.yml`.

To deploy automatically from GitHub, set the secret:

- `RAILWAY_TOKEN`

and ensure your Railway service name matches `opticell-backend`.
