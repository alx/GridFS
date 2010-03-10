# GridFS

Sinatra frontend for managing files on GridFS.
It's currently in test and shouldn't be used in production environment.

## Features

* Upload files with metadata
* Response: json, thumbnail, original file
* Create your own router in /lib/router to add routes and fetch your content
* Works with [Uploadify](http://www.uploadify.com/), please set your domain in /public/crossdomain.xml

## Installation

* Setup an admin username and password in /init_config.yaml
* Run the app: ruby application.rb

## !!! Improve security !!!

Use HTTP-POST for edit-delete action, it currently uses HTTP-GET as I needed to use these actions
on another domain with jQuery method $.getJSON().

The same for user authentication: if someone has a method to improve it, it'll be greatly welcomed.

## User Interface

We've got an external application using GridFS, please contact us if you need it now, this application
should be released soon.