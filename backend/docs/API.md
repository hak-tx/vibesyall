# VIBES Y'ALL API

Base URL is the deployed Worker, for example `https://vibe-map-api.<account>.workers.dev`.

The API exposes public aggregate place sentiment while keeping raw vibe events private.

## GET /health

Returns service health and the active data-model marker.

```json
{
  "ok": true,
  "service": "vibe-map-api",
  "data_model": "human_labeled_place_sentiment_v1"
}
```

## GET /vibes/tags

Returns active canonical vibe tags in display order.

```json
{
  "tags": [
    {
      "id": "changed_my_life",
      "slug": "changed_my_life",
      "display_name": "Changed my Life",
      "emoji": "⭐",
      "sentiment_group": "positive",
      "sort_order": 10,
      "is_active": true
    }
  ]
}
```

## POST /places

Creates or upserts a place. If `provider_place_id` is present, the backend treats `provider + provider_place_id` as the stable identity.

```json
{
  "provider": "mapkit",
  "provider_place_id": "mapkit-place-id",
  "name": "Joe's Tiny Taco Window",
  "latitude": 30.2672,
  "longitude": -97.7431,
  "street_address": "604 Congress Ave",
  "category": "Restaurant",
  "city": "Austin",
  "region": "TX",
  "country": "US"
}
```

## GET /places/:id

Returns place details, aggregate stats, and this device's existing vibe if `X-Vibe-Device-ID-Hash` is supplied.

The response exposes aggregates only, not the raw event table.

```json
{
  "place": {
    "id": "place_abc",
    "provider": "mapkit",
    "provider_place_id": "mapkit-place-id",
    "name": "Joe's Tiny Taco Window",
    "latitude": 30.2672,
    "longitude": -97.7431,
    "street_address": "604 Congress Ave",
    "category": "Restaurant",
    "city": "Austin",
    "region": "TX",
    "country": "US",
    "stats": {
      "rating_count": 18,
      "total_vibes": 18,
      "top_vibe_tag_id": "fire",
      "top_vibe_percent": 67,
      "second_vibe_tag_id": "iconic",
      "second_vibe_percent": 50,
      "last_30_day_total_vibes": 7,
      "last_30_day_top_vibe_tag_id": "fire",
      "last_30_day_top_vibe_percent": 71,
      "last_year_total_vibes": 18,
      "last_year_top_vibe_tag_id": "fire",
      "last_year_top_vibe_percent": 67,
      "top_vibes": [
        {
          "vibe_tag_id": "fire",
          "slug": "fire",
          "display_name": "Fire",
          "emoji": "🔥",
          "sentiment_group": "positive",
          "count": 12,
          "percentage": 67
        }
      ]
    },
    "my_vibe_event": null,
    "my_rating": null
  }
}
```

## GET /places/nearby?lat=&lng=&radius=&vibe_tag=

Returns saved nearby places with at least one active vibe event.
Radius defaults to `5000` meters and is capped at `650000` meters so wider map zooms can still show city-level clusters.

Use `vibe_tag` to filter by canonical tag id, slug, display name, or known legacy label.

## POST /vibes

Creates or updates one current vibe event for one anonymous user at one place.
The database enforces `UNIQUE(place_id, anonymous_user_id)` to prevent unlimited duplicate votes.

Accepted tag inputs:

- `primary_vibe_tag_id`
- `secondary_vibe_tag_id`
- `third_vibe_tag_id`
- `primary_vibe_tag_slug`
- `secondary_vibe_tag_slug`
- `third_vibe_tag_slug`
- `vibe_tags`

Selected vibes cannot resolve to the same active tag, and a submission can include at most three tags.

```json
{
  "place_id": "place_abc",
  "device_id_hash": "64-character-sha256-hex",
  "vibe_tags": ["fire", "iconic", "worth_the_drive"],
  "source": "ios",
  "app_version": "0.1.0"
}
```

The response returns the updated place aggregates and the saved private event summary for the submitting device.

```json
{
  "place": {},
  "vibe_event": {
    "id": "event-id",
    "place_id": "place_abc",
    "anonymous_user_id": "anon_hashprefix",
    "primary_vibe_tag_id": "fire",
    "secondary_vibe_tag_id": "iconic",
    "third_vibe_tag_id": "worth_the_drive",
    "vibe_tag_ids": ["fire", "iconic", "worth_the_drive"],
    "source": "ios",
    "app_version": "0.1.0",
    "created_at": "2026-06-28T00:00:00.000Z",
    "updated_at": "2026-06-28T00:00:00.000Z",
    "moderation_status": "active"
  },
  "discovery": {
    "was_first_vibe": false
  }
}
```

## POST /reports

Reports a place or suspected abuse.

Allowed reasons:

- `wrong_place`
- `duplicate_place`
- `spam_or_brigading`
- `inappropriate`
- `other`

```json
{
  "place_id": "place_abc",
  "device_id_hash": "64-character-sha256-hex",
  "reason": "duplicate_place"
}
```

## Legacy Compatibility

Current iOS builds still use these routes:

- `GET /vibes`
- `POST /ratings`
- `POST /places/:id/report`

`POST /ratings` now writes to `vibe_events` through the same code path as `POST /vibes`.
The older response fields are preserved for app compatibility, but new backend consumers should use canonical tag ids from `/vibes/tags`.
