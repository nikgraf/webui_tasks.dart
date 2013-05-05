A Webui task library based on Hop.
==================================

# What is Webui?

Webui allows you to create web applications like you would legos, piecing the framework from reusable components.
See [article](http://www.dartlang.org/articles/web-ui/) for an introduction.

# What is Hop?

Hop is a framework that simplifies and automates console tasks in Dart.  See [Hop Pub package](http://pub.dartlang.org/packages/hop) for more information.  Also see [article](https://github.com/kevmoo/bot.dart/wiki/Using-Hop%2C-Part-1%3A-Building-and-Running-Your-First-Hop-Task-Application) for a quick tutorial.

# How will this library help me?

This library will allow you to:
* Compile webui components to Javascript in one console step as well as minidart compilation (dart to dart). [[In Development](https://github.com/damondouglas/webui_tasks.dart/issues/milestones)]
* Fix the relative Urls in the output Webui entry point Html file. [[Done!](https://github.com/damondouglas/webui_tasks.dart/issues/5)]
* Copy static assets such as Javascript linked from the entry point Html file into the target output directory. [[Done!](https://github.com/damondouglas/webui_tasks.dart/issues/4)]

# How do I get started?

This library isn't yet published on [pub](http://http://pub.dartlang.org/).  Meanwhile, you can add the following dependency:

```yaml
dependencies:
  webui_tasks:
    git: https://github.com/damondouglas/webui_tasks.dart
```

## Authors
 * [Damon Douglas](https://github.com/damondouglas) ([+Damon Douglas](https://plus.google.com/u/0/108940381045821372455/))
 * _You? File bugs. Fork and Fix bugs. Let's build this community._

## Acknowledgements
* [Kevin Moore](https://github.com/kevmoo)'s for his work on the [Hop](https://github.com/kevmoo/hop.dart) and [Webui Widget](https://github.com/kevmoo/widget.dart) libraries, from which much of this code and methodology derives.
* [Seth Ladd](https://github.com/sethladd) for [his original idea](https://groups.google.com/a/dartlang.org/forum/?fromgroups=#!topic/web-ui/Xvk3BU8NnxI) that inspired the project.
