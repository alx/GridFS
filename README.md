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

==========

Copyright (c) 2010 Alexandre Girard

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
