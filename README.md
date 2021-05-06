Super simple CLI to create a new Jekyll/Markdown blog post. When combined with the included Automator workflow, it lets you do something like this:

![](https://i.imgur.com/6EFBRah.png)

Command line usage looks like this:

```bash
$ CreateNewBlogPost --title "Now's the Time" .
```

It creates a file named `"yyyy-MM-dd-nows-the-time.md"` in the specified directory, and pre-fills it with the (currently hard-coded) template:

```markdown
---
layout: post
title: "Now's the Time"
date: 2021-05-06 04:20:57 -0700
excerpt: ""
categories:
  -
tags: [frontpage]
image:
  path: { imageURL }
  width:
  height:
---

<div style="text-align: left; margin-bottom: 2em;"><img src="{ imageURL }"></div>a
```
