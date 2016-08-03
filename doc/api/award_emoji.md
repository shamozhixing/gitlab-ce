# Award Emoji

 >**Note:** This feature was introduced in GitLab 8.9

An awarded emoji tells a thousand words, and can be awarded on issues, merge
requests and notes/comments. Issues, merge requests and notes are further called
`awardables`.

## Issues and merge requests

### List an awardable's award emoji

Gets a list of all award emoji

```
GET /projects/:id/issues/:issue_id/award_emoji
GET /projects/:id/merge_requests/:merge_request_id/award_emoji
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a project |
| `awardable_id` | integer | yes | The ID of an awardable |

```bash
curl -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" http://gitlab.example.com/api/v3/projects/1/issues/80/award_emoji
```

Example Response:

```json
[
  {
    "id": 4,
    "name": "1234",
    "user": {
      "name": "Administrator",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/u/root"
    },
    "created_at": "2016-06-15T10:09:34.206Z",
    "updated_at": "2016-06-15T10:09:34.206Z",
    "awardable_id": 80,
    "awardable_type": "Issue"
  },
  {
    "id": 1,
    "name": "microphone",
    "user": {
      "name": "User 4",
      "username": "user4",
      "id": 26,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/u/user4"
    },
    "created_at": "2016-06-15T10:09:34.177Z",
    "updated_at": "2016-06-15T10:09:34.177Z",
    "awardable_id": 80,
    "awardable_type": "Issue"
  }
]
```

### Get single award emoji

Gets a single award emoji from an issue or merge request.

```
GET /projects/:id/issues/:issue_id/award_emoji/:award_id
GET /projects/:id/merge_requests/:merge_request_id/award_emoji/:award_id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a project |
| `awardable_id` | integer | yes | The ID of an awardable |
| `award_id` | integer | yes | The ID of the award emoji |

```bash
curl -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" http://gitlab.example.com/api/v3/projects/1/issues/80/award_emoji/1
```

Example Response:

```json
{
  "id": 1,
  "name": "microphone",
  "user": {
    "name": "User 4",
    "username": "user4",
    "id": 26,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/u/user4"
  },
  "created_at": "2016-06-15T10:09:34.177Z",
  "updated_at": "2016-06-15T10:09:34.177Z",
  "awardable_id": 80,
  "awardable_type": "Issue"
}
```

### Award a new emoji

This end point creates an award emoji on the specified resource

```
POST /projects/:id/issues/:issue_id/award_emoji
POST /projects/:id/merge_requests/:merge_request_id/award_emoji
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a project |
| `awardable_id` | integer | yes | The ID of an awardable |
| `name` | string | yes | The name of the emoji, without colons |

```bash
curl -X POST -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" http://gitlab.example.com/api/v3/projects/1/issues/80/award_emoji?name=blowfish
```

Example Response:

```json
{
  "id": 344,
  "name": "blowfish",
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/u/root"
  },
  "created_at": "2016-06-17T17:47:29.266Z",
  "updated_at": "2016-06-17T17:47:29.266Z",
  "awardable_id": 80,
  "awardable_type": "Issue"
}  
```

### Delete an award emoji

Sometimes its just not meant to be, and you'll have to remove your award. Only available to
admins or the author of the award. Status code 200 on success, 401 if unauthorized.

```
DELETE /projects/:id/issues/:issue_id/award_emoji/:award_id
DELETE /projects/:id/merge_requests/:merge_request_id/award_emoji/:award_id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a project |
| `issue_id` | integer | yes | The ID of an issue |
| `award_id` | integer | yes | The ID of a award_emoji |

```bash
curl -X DELETE -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" http://gitlab.example.com/api/v3/projects/1/issues/80/award_emoji/344
```

Example Response:

```json
{
  "id": 344,
  "name": "blowfish",
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/u/root"
  },
  "created_at": "2016-06-17T17:47:29.266Z",
  "updated_at": "2016-06-17T17:47:29.266Z",
  "awardable_id": 80,
  "awardable_type": "Issue"
}
```

## Award Emoji on Notes

The endpoints documented above are available for Notes as well. Notes
are a sub-resource of Issues and Merge Requests. The examples below
describe working with Award Emoji on notes for an Issue, but can be
easily adapted for notes on a Merge Request.

### List a note's award emoji

```
GET /projects/:id/issues/:issue_id/notes/:note_id/award_emoji
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a project |
| `issue_id` | integer | yes | The ID of an issue |
| `note_id` | integer | yes | The ID of an note |


```bash
curl -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" http://gitlab.example.com/api/v3/projects/1/issues/80/notes/1/award_emoji
```

Example Response:

```json
[
  {
    "id": 2,
    "name": "mood_bubble_lightning",
    "user": {
      "name": "User 4",
      "username": "user4",
      "id": 26,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/u/user4"
    },
    "created_at": "2016-06-15T10:09:34.197Z",
    "updated_at": "2016-06-15T10:09:34.197Z",
    "awardable_id": 1,
    "awardable_type": "Note"
  }
]
```

### Get single note's award emoji

```
GET /projects/:id/issues/:issue_id/notes/:note_id/award_emoji/:award_id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a project |
| `issue_id` | integer | yes | The ID of an issue |
| `note_id` | integer | yes | The ID of a note |
| `award_id` | integer | yes | The ID of the award emoji |

```bash
curl -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" http://gitlab.example.com/api/v3/projects/1/issues/80/notes/1/award_emoji/2
```

Example Response:

```json
{
  "id": 2,
  "name": "mood_bubble_lightning",
  "user": {
    "name": "User 4",
    "username": "user4",
    "id": 26,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/u/user4"
  },
  "created_at": "2016-06-15T10:09:34.197Z",
  "updated_at": "2016-06-15T10:09:34.197Z",
  "awardable_id": 1,
  "awardable_type": "Note"
}
```

### Award a new emoji on a note

```
POST /projects/:id/issues/:issue_id/notes/:note_id/award_emoji
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a project |
| `issue_id` | integer | yes | The ID of an issue |
| `note_id` | integer | yes | The ID of a note |
| `name` | string | yes | The name of the emoji, without colons |

```bash
curl -X POST -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" http://gitlab.example.com/api/v3/projects/1/issues/80/notes/1/award_emoji?name=rocket
```

Example Response:

```json
{
  "id": 345,
  "name": "rocket",
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/u/root"
  },
  "created_at": "2016-06-17T19:59:55.888Z",
  "updated_at": "2016-06-17T19:59:55.888Z",
  "awardable_id": 1,
  "awardable_type": "Note"
}
```

### Delete an award emoji

Sometimes its just not meant to be, and you'll have to remove your award. Only available to
admins or the author of the award. Status code 200 on success, 401 if unauthorized.

```
DELETE /projects/:id/issues/:issue_id/notes/:note_id/award_emoji/:award_id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a project |
| `issue_id` | integer | yes | The ID of an issue |
| `note_id` | integer | yes | The ID of a note |
| `award_id` | integer | yes | The ID of a award_emoji |

```bash
curl -X DELETE -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" http://gitlab.example.com/api/v3/projects/1/issues/80/award_emoji/345
```

Example Response:

```json
{
  "id": 345,
  "name": "rocket",
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/u/root"
  },
  "created_at": "2016-06-17T19:59:55.888Z",
  "updated_at": "2016-06-17T19:59:55.888Z",
  "awardable_id": 1,
  "awardable_type": "Note"
}
```
