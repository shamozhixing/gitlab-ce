# Issue Triage Policies

As of June 2016 we have more than 4000 open issues - and this number is growing every day.

In order to keep the GitLab projects' issue trackers maintainable, the policies outlined below were created and will be enforced.

## Policies

### Outdated Issues

For issues that haven't been updated in the last 3 months the "Awaiting Feedback" label should be added to the issue. After two weeks (14 days), if no response has been made by anyone on the issue, the issue should be closed. This is a slightly modified version of the Rails Core policy on outdated issues.

If they respond at any point in the future, the issue can be considered for reopening. If we can't confirm an issue still exists in recent versions of GitLab, we're just adding noise to the issue tracker.

### Duplicates

Before opening a new issue, make sure to **search for keywords** and verify your issue isn't a duplicate.

Be diligent about checking for duplicates and/or reporting duplicates when you notice them.

All things held equal, the earliest issue should be considered the canonical version. If one issue has a better title, description, and/or more comments and positive reactions, it should be prioritized over earlier issues even if it's a duplicate.

### Err on the side of closing

We simply can't satisfy everyone. We need to balance pleasing users as much as possible with keeping the project maintainable.

- If the issue is a bug report without reproduction steps or version information, close the issue and ask the reporter to provide more information.
- If we're definitely not going to add a feature/change, say so and close the issue.

### Label issues as they come in

As of June 2016, 1900 of the more-than-4000 open issues remain unlabeled. When creating an issue, label it. When an issue comes in, it should be triaged and labeled.

### Take ownership of issues you've opened

Sort by "Author: your username" and close any issues which you know have been fixed or have become irrelevant for other reasons. Label them if they're not labeled already.

### Questions/Support Issues

If it's a question, or something vague that can't be addressed by the development team for whatever reason, close it and direct them to the relevant support resources we have (e.g. our Discourse forum or emailing Support).

### New Labels

If you notice a common pattern amongst various issues (e.g. a new feature that doesn't have a dedicated label yet), suggest adding a new label in chat.

Douwe is the "Label King", make sure he approves of a label before adding it. This way we don't have a bunch of repetitive/unused/inconsistent labels.

## Notes

The original issue about these policies is [#17693][17693]. We'll be working to improve the situation from within GitLab itself as time goes on.

The following projects, resources, and blog posts were very helpful in crafting these policies:

- [CodeTriage][code-triage]
- [Steve Klabnik's "How to be an open source gardener"][open-source-gardener]
- [Managing the Deluge of Atom Issues][atom-issues]

[17693]: https://gitlab.com/gitlab-org/gitlab-ce/issues/17693
[code-triage]: https://www.codetriage.com/
[open-source-gardener]: http://words.steveklabnik.com/how-to-be-an-open-source-gardener
[atom-issues]: http://blog.atom.io/2016/04/19/managing-the-deluge-of-atom-issues.html
